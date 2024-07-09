#!/usr/bin/env python3

# This script was written for the NIH BioData Catalyst to process an input manifest file
# containing file locations and file metadata, and generate an output manifest file with
# cloud data needed for indexing.
#
# usage: generate_manifest_for gcloud.py [-h] --bucket BUCKET --tsv TSV [--gs] [--aws] [--test] 
#                   [--threads THREADS] [--chunk-size CHUNK_SIZE]
#
# required arguments:
# --bucket				bucket
# --tsv					local file path to input manifest file 
#
#
# optional arguments:
# -h, --help            show help message
# --test                test mode: confirm input manifest file is valid
# --threads THREADS     number of concurrent threads (default: number of CPUs on machine)


import argparse
import subprocess
import datetime
import hashlib
import fileinput
import csv
import signal
import sys
import time
import io
import os
import tempfile
import uuid
from os import access, R_OK
from os.path import isfile, basename
from collections import OrderedDict 
from urllib.parse import urlparse

import threading
import concurrent.futures
import multiprocessing.pool

# for aws s3
import logging
import boto3
import botocore

# for google storage
from google.cloud import storage
from google.oauth2 import service_account
from googleapiclient.discovery import build
from google.api_core.exceptions import BadRequest, Forbidden
from google.cloud.exceptions import NotFound

out_file_path = ''
out_file = ''
cloud_bucket_name = ''

# 1. Read and Verify Input Manifest File
# 2. If --gs is set, then lookup google cloud metadata for manifest
# 3. If -aws is set, then lookup aws metadata for manifest
# 4. Write out receipt manifest file

def main():
	args = parse_args()
	print('Script running on', sys.platform, 'with', os.cpu_count(), 'cpus')

	# process file
	od = OrderedDict()
	read_and_verify_file(od, args) 

	global out_file
	out_file = get_receipt_manifest_file_pointer(args.tsv.name)	

	verify_gcloud_uploads(od, args.threads)		
	update_manifest_file(out_file, od)
				
	out_file.close()
	upload_manifest_file(out_file)
	print("Done. Receipt manifest located at", out_file_path)

# Generate name for receipt manifest file by replacing ".tsv" in input manifest file with
# ".<datetime>.manifest.tsv" and return file pointer to it.

def get_receipt_manifest_file_pointer(input_manifest_file_path):
	manifest_filepath = input_manifest_file_path
	timestr = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d%H%M%S")
	
	if (manifest_filepath.endswith('.tsv')):
		manifest_filepath = manifest_filepath.replace(".tsv", ".manifest." + timestr + ".tsv")	
	else:
		manifest_filepath += '.manifest.' + timestr + '.tsv'
	global out_file_path
	out_file_path = manifest_filepath
	f = open(manifest_filepath, 'wt')
	return f		

# upload receipt manifest file to each cloud bucket that had content uploaded

def upload_manifest_file(receipt_manifest_file):
	storage_client = storage.Client()
	print("Uploading ", receipt_manifest_file.name, " to gs://", cloud_bucket_name, sep='')
	bucket = storage_client.bucket(cloud_bucket_name)
	blob = bucket.blob(basename(receipt_manifest_file.name))
	blob.upload_from_filename(receipt_manifest_file.name)

# Parse user arguments and confirm valid arguments.

def parse_args():
	parser = argparse.ArgumentParser(description='Process TSV file.')
	parser.add_argument('--tsv', required=True, type=argparse.FileType('r'), help='tsv file')
	parser.add_argument('--bucket', required=True , help='cloud bucket name')
	parser.add_argument('--test', default=False, action='store_true', help='test mode: confirm input manifest file is valid')
	parser.add_argument('--threads', type=int, default=os.cpu_count(), help='number of concurrent threads (default: number of CPUs on machine)')
	parser.add_argument('--chunk-size', type=int, default=8 * 1024 * 1024, help='mulipart-chunk-size for uploading (default: 8 * 1024 * 1024)')
	
	args = parser.parse_args()
	if (len(sys.argv) == 0):
		parser.print_help()
		
	return args

# For each row in the input manifest file, confirm that file is readable, and buckets to
# write to are writeable by the user.

def read_and_verify_file(od, args) :

	reader = csv.DictReader(args.tsv, dialect='excel-tab')
	for row in reader:
		process_row(od, args.bucket, row, args.test)
	if (verify_gs_bucket(args.bucket, od, args.test) == False):
		print("Bucket does not exist or is not writeable:", args.bucket)
		exit()

# For each row, add the information to the ordered dictionary for the manifest file. 
					
def process_row(od, bucket, row, test_mode):
	input_file = row['input_file_path']

	row['file_name'] = basename(input_file)
	if ('file_name' not in row or 'guid' not in row or 'ga4gh_drs_uri' not in row or 'md5sum' not in row):
		print("manifest file missing of the following required fields: file_name, guid, ga4gh_drs_uri, md5sum")		
		exit()
		
	row['gs_crc32c'] = ''
	row['gs_path'] = ''
	row['gs_modified_date'] = ''
	row['gs_file_size'] = ''

	od[input_file] = row

# Confirm all Google Storage buckets writeable by the user
    	   
def verify_gs_bucket(bucket, od, test_mode):
	storage_client = storage.Client()

	if (gs_bucket_writeable(bucket, storage_client, test_mode) == False):		
		print("bucket not writeable:", bucket)
		return False

	global cloud_bucket_name
	cloud_bucket_name = bucket
	return True
		
# Confirm Google Storage bucket writeable by the user

def gs_bucket_writeable(bucket_name, storage_client, test_mode):
	try:
		bucket = storage_client.bucket(bucket_name)
#			if (bucket.exists()):
		returnedPermissions = bucket.test_iam_permissions('storage.objects.create')
#				print('PERMISSIONS for', bucket_name, returnedPermissions)
		if ('storage.objects.create' in returnedPermissions):
			return True
		else:
			print('ERROR: gs bucket is not writeable', bucket_name)
			return False					
	except BadRequest as e:
		print('ERROR: gs bucket does not exist -', bucket_name, e)
		return False
	except Forbidden as e2:
		print('ERROR: gs bucket is not accessible by user -', bucket_name, e2)
		return False
	except Exception as e3:
		print(e3)
		print('ERROR: gs bucket does not exist or is not accessible by user -', bucket_name, e3)
		return False			


def verify_gcloud_uploads(od, threads):
	storage_client = storage.Client()
	bucket_name = get_bucket_name()
	bucket = storage_client.bucket(bucket_name)

	print("Verifying Uploads and Fetching Metadata")
	with concurrent.futures.ThreadPoolExecutor(threads) as executor:
		futures = [executor.submit(verify_gcloud_upload, value, bucket, bucket_name) for key, value in od.items()]
		print("Executing total", len(futures), "jobs with", threads, "threads")
		for idx, future in enumerate(concurrent.futures.as_completed(futures)):
			try:
				res = future.result()
#				print("Processed job", idx, "result", res)	
			except ValueError as e:
				print(e)

def verify_gcloud_upload(value, bucket, bucket_name):
	path = value['s3_path']
	path = path.split("s3://" + bucket_name + '/',1)[1] 

#	print("checking blob gs://" + bucket_name + '/' +  path)
	blob = bucket.get_blob(path)
	if ((blob is not None) and blob.exists()):
		blob.reload()
		value['gs_crc32c'] = blob.crc32c
		add_gs_manifest_metadata(value, blob, "gs://" + bucket_name + '/' +  path, path)
	else: 
		print("Blob does not exist: gs://" + bucket_name + '/' + path)

# Given the blob object from Google Cloud, adds data into the ordered dictionary that will
# be output by the receipt manifest file

def add_gs_manifest_metadata(fields, blob, gs_path, input_file_path):
		fields['gs_path'] = gs_path
		fields['gs_modified_date'] = format(blob.updated)
		fields['gs_file_size'] = blob.size
		if (len(fields['md5sum']) == 0):
			if (blob.md5_hash):
				fields['md5sum'] =  base64.b64decode(blob.md5_hash).hex()
			else:
				md5sum = calculate_md5sum(input_file_path)
				fields['md5sum'] = md5sum
		if (not fields['ga4gh_drs_uri'].startswith("drs://")):
# FIXME	
#			add_drs_uri_from_path(fields, gs_path)
			add_new_drs_uri(fields)
	
def get_bucket_name():
	return cloud_bucket_name
	
# This method gets called after each checksum and upload so that as much state as possible
# is written out to the receipt manifest file.

def update_manifest_file(f, od):
	with threading.Lock():
		# start from beginning of file
		f.seek(0)
		f.truncate()
	
		isfirstrow = True
		tsv_writer = csv.writer(f, delimiter='\t')
		for key, value in od.items():
			if (isfirstrow):
				# print header row
				tsv_writer.writerow(value.keys())
				isfirstrow = False 
			tsv_writer.writerow(value.values())
	# we don't close the file until the end of the operation

# If a quit is detected, then this method is called to save state.
#
# adapted from here: https://stackoverflow.com/questions/18114560/python-catch-ctrl-c-command-prompt-really-want-to-quit-y-n-resume-executi/18115530

def exit_and_write_manifest_file(signum, frame):
	print ("Detected Quit. Please use the resume manifest file '", out_file_path, "'to resume your job.", sep ='')
	if (out_file):
		out_file.close()
	sys.exit(1)
       
if __name__ == '__main__':
    signal.signal(signal.SIGINT, exit_and_write_manifest_file)
    signal.signal(signal.SIGTERM, exit_and_write_manifest_file)    
    signal.signal(signal.SIGHUP, exit_and_write_manifest_file)    
    main()
