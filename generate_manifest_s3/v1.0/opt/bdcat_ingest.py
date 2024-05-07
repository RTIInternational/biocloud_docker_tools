import shutil
import base64
import csv
import datetime
import os
from os.path import isfile, basename, join, splitext
import subprocess
import threading
import uuid
from urllib.parse import urlparse
import tempfile
from os import access, R_OK

import concurrent.futures
import struct
import crcmod
import hashlib

from collections import OrderedDict 

from google.cloud import storage
from google.oauth2 import service_account
from googleapiclient.discovery import build
from google.api_core.exceptions import BadRequest, Forbidden
from google.cloud.exceptions import NotFound
from google.cloud.storage.retry import DEFAULT_RETRY

# for aws s3
import logging
import boto3
import botocore

def get_bucket_name(row):
	return 'nih-nhlbi-' + row['study_id'].replace(".", "-") + '-' + row['consent_group']

def gcs_bucket_writeable(bucket_name):
	storage_client = storage.Client()

	try:
		bucket = storage_client.bucket(bucket_name)
		returnedPermissions = bucket.test_iam_permissions('storage.objects.create')
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

def generate_dict_from_gcs_bucket(gcs_bucket, study_id, consent_group):
	od = OrderedDict()
	# logging.warning(f"gcs-bucket: {gcs_bucket}")
	print(f"gcs-bucket: {gcs_bucket}")
	client = storage.Client()
	blobs = client.list_blobs(gcs_bucket)

	for blob in blobs:
#		print(blob.name)
		row = get_empty_file_metadata()
		blob.reload()
		row['input_file_path'] = 'gs://' + gcs_bucket + '/' + blob.name
		row['study_id'] = study_id
		row['consent_group'] = consent_group 	
		row['file_name'] = 'gs://' + gcs_bucket + '/' + blob.name
		row['file_size'] = blob.size
		row['file_crc32c'] = blob.crc32c
		row['gs_crc32c'] = blob.crc32c		
		if (blob.md5_hash):
			row['md5sum'] = base64.b64decode(blob.md5_hash).hex()
		row['file_size'] = blob.size
		add_gs_manifest_metadata(row, blob, row['input_file_path'], row['input_file_path'])
		od[blob.name] = row
	return od

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
			add_drs_uri_from_path(fields, gs_path)

def generate_dict_from_s3_bucket(s3_bucket, study_id, consent_group):
	od = OrderedDict()

	print(f"s3-bucket: {s3_bucket}")
	# logging.warning(f"s3-bucket: {s3_bucket}")
	aws_client = boto3.client('s3')	

	paginator = aws_client.get_paginator('list_objects_v2')
	pages = paginator.paginate(Bucket=s3_bucket, Prefix='')

	for page in pages:
		for obj in page['Contents']:
#			print(obj)
			key = obj['Key']
			row = {}
			row['input_file_path'] = 's3://' + s3_bucket + '/' + key
			row['file_name'] = 's3://' + s3_bucket + '/' + key
			row['s3_file_size'] = obj['Size']
			row['s3_md5sum'] = obj['ETag'][1:-1]
			if ("-" not in row['s3_md5sum']):
				row['md5sum'] = row['s3_md5sum']
			else:
				row['md5sum'] = ''
			row['s3_path'] = row['file_name']
			row['s3_modified_date'] = format(obj['LastModified'])
			od[key] = row
	return od

def add_aws_manifest_metadata(fields, response, path):
	file_size = response['ContentLength']
#	print ("size:", file_size)
	md5sum = response['ETag'][1:-1]
	if ("-" not in md5sum):
		fields['md5sum'] = md5sum
	print(f"checksum check: {fields['s3_md5sum']} : {md5sum}")
	if (fields['s3_md5sum'] != md5sum):
#		print('same checksum')
#	else:
		print('different checksum')
	fields['s3_path'] = path
	fields['s3_modified_date'] = format(response['LastModified'])
	fields['s3_file_size'] = file_size
	if (len(fields['md5sum']) == 0):
		md5sum = calculate_md5sum(fields['input_file_path'])
		fields['md5sum'] = md5sum
	if (not fields['ga4gh_drs_uri'].startswith("drs://")):
		add_drs_uri_from_path(fields, path)

def get_empty_file_metadata():
	row = {}
	row['input_file_path'] = ''
	row['study_id'] = ''
	row['consent_group'] = '' 	
	row['file_type'] = '' 	
	row['file_name'] = ''
	row['file_size'] = ''
	row['file_crc32c'] = ''
	row['guid'] = ''
	row['ga4gh_drs_uri'] = ''
	row['md5sum'] = ''
	row['gs_crc32c'] = ''
	row['gs_path'] = ''
	row['gs_modified_date'] = ''
	row['gs_file_size'] = ''
	row['s3_md5sum'] =''
	row['s3_path'] = ''
	row['s3_modified_date'] = ''
	row['s3_file_size'] = ''
	return row

def get_file_metadata_for_file_path(file_path, study_id, consent_group):
	row = get_empty_file_metadata()
	row['study_id'] = study_id
	row['consent_group'] = consent_group
	row['file_name'] = file_path
	row['file_size'] = os.stat(file_path).st_size
	row['file_type'] = os.path.splitext(file_path)[1][1:]	
	return row
	
def get_receipt_manifest_file_pointer_for_bucket(bucket_name):
	# print(f"get_receipt_manifest_file_pointer_for_bucket")
	timestr = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d%H%M%S")
	manifest_filepath = bucket_name + '.manifest.' + timestr + '.tsv'
	f = open(manifest_filepath, 'wt')
	print(f"get_receipt_manifest_file_pointer_for_bucket - done")
	return f

def get_manifest_file_pointer_for_directory(directory_name):
	timestr = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d%H%M%S")
	manifest_filepath = directory_name + '.tsv'
	f = open(manifest_filepath, 'wt')
	return f


def download_gcs_bucket_to_localdisk(gcs_bucket, gcs_user_project):
	subprocess.check_call([
		'gsutil', '-u', gcs_user_project,
		'-m', 'cp',
		'-r', 'gs://%s' % (gcs_bucket), '.'
	])
	print('downloaded gs://%s to %s' % (gcs_bucket, gcs_bucket))
	# logging.warning(f"downloaded gs://{gcs_bucket} to {gcs_bucket}")

def upload_from_localdisk_to_gcs_bucket(directory_path, upload_gcs_bucket_name, gcs_user_project):
	if (gcs_user_project != ''):
		subprocess.check_call([
			'gsutil', '-u', gcs_user_project,
			'-m', 'cp',
			'-r', directory_path, 'gs://%s' % (upload_gcs_bucket_name)
		])	
	else:
		subprocess.check_call([
			'gsutil',
			'-m', 'cp',
			'-r', directory_path, 'gs://%s' % (upload_gcs_bucket_name)
		])
		
	print('uploaded %s to gs://%s' % (directory_path, upload_gcs_bucket_name))
	# logging.warning(f"uploaded {directory_path} to gs://{upload_gcs_bucket_name}")
# aws s3 cp --recursive idc-tcia-tcga-blca s3://idc-tcia-tcga-blca--oa --acl bucket-owner-full-control

def upload_from_localdisk_to_s3_bucket(directory_path, upload_s3_bucket_name, acl_arg):
	if (acl_arg != ''):
		subprocess.check_call([
			'aws', 's3', 'cp', '--recursive', directory_path, 's3://%s' % (upload_s3_bucket_name),
			'--acl', acl_arg,
		])	
	else:
		subprocess.check_call([
			'aws', 's3', 'cp', '--recursive', directory_path, 's3://%s' % (upload_s3_bucket_name)
		])	
		
	print('uploaded %s to s3://%s' % (directory_path, upload_s3_bucket_name))
	# logging.warning(f"uploaded {directory_path} to s3://{upload_s3_bucket_name}")

def add_metadata_for_uploaded_gcs_bucket(exclude_path, od, upload_gcs_bucket_name):
	storage_client = storage.Client()

	bucket = storage_client.bucket(upload_gcs_bucket_name)
	for key, row in od.items():
		file_path = row['file_name']
		if ('intermediate_file_name' in row and row['intermediate_file_name'] != ''):
			file_path = row['intermediate_file_name']
		if (exclude_path != ''):
			file_path = file_path.replace(exclude_path, '')
		blob = bucket.blob(file_path)
		blob.reload(timeout=120, retry=DEFAULT_RETRY)
		row['gs_path'] = 'gs://' + upload_gcs_bucket_name+ '/' + blob.name
		row['gs_modified_date'] = format(blob.updated)
		row['gs_file_size'] = blob.size
		row['gs_crc32c'] = blob.crc32c	
		if (row['file_crc32c'] != row['gs_crc32c']):
			print("Checksum for", blob.name, "did not match:", row['file_crc32c'], '!=', row['gs_crc32c'])
			# logging.warning(f"Checksum for {blob.name} did not match: {row['file_crc32c']} != {row['gs_crc32c']}")
			
def upload_manifest_file_to_gcs_bucket(receipt_manifest_file_path, upload_gcs_bucket_name):
	storage_client = storage.Client()
	print("Uploading ", receipt_manifest_file_path, " to gs://", upload_gcs_bucket_name, sep='')
	bucket = storage_client.bucket(upload_gcs_bucket_name)
	blob = bucket.blob(basename(receipt_manifest_file_path))
	blob.upload_from_filename(receipt_manifest_file_path)
	# logging.warning(f"Uploading {receipt_manifest_file_path} to gs://{upload_gcs_bucket_name} done")

def upload_manifest_file_to_s3_bucket(receipt_manifest_file_path, upload_s3_bucket_name):
	destination_path = f'/opt/output/{os.path.basename(receipt_manifest_file_path)}'    
	# Copy the file to /opt/data directory
	shutil.copy(receipt_manifest_file_path, destination_path)
	print(f"Copied {receipt_manifest_file_path} to {destination_path}")
	aws_client = boto3.client('s3')
	aws_client.upload_file(receipt_manifest_file_path, upload_s3_bucket_name, basename(receipt_manifest_file_path))
	print("Uploading ", receipt_manifest_file_path, " to s3://", upload_s3_bucket_name, " done", sep='')
	# logging.warning(f"Uploading {receipt_manifest_file_path} to s3://{upload_s3_bucket_name} done")

def update_metadata_for_s3_keys(od):
	for key, row in od.items():
		s3_path = row['s3_path']
		(bucket_name, key) = get_bucket_and_key_for_cloud_url(s3_path)
		add_metadata_for_s3_key(bucket_name, key, row)

def add_metadata_for_s3_key(bucket_name, key, fields):
	s3 = boto3.client('s3')
	try:
		response = s3.head_object(Bucket=bucket_name, Key=key)
	except botocore.exceptions.ClientError as e:
		print("Error getting metadata for ", key)
		print(e)
		
	add_aws_manifest_metadata(fields, response, 's3://' + bucket_name + '/' + key)	

def add_aws_manifest_metadata(fields, response, path):
	file_size = response['ContentLength']
	fields['s3_md5sum'] = response['ETag'][1:-1]
	fields['s3_path'] = path
	fields['s3_modified_date'] = format(response['LastModified'])
	fields['s3_file_size'] = file_size
	print('updated aws fields:', fields)
	
def assign_guids(od):
	for key, row in od.items():
		add_new_drs_uri(row)
		
def add_new_drs_uri(row):
	if ('ga4gh_drs_uri' not in row or not row['ga4gh_drs_uri'].startswith('drs://')):
		x = uuid.uuid4()		
		row['guid'] = 'dg.4503/' + str(x)
		row['ga4gh_drs_uri'] = "drs://dg.4503:dg.4503%2F" + str(x)

def calculate_crc32c_threaded(od, num_threads):
	print('Calculating crc32c checksums with', num_threads, 'threads')
	logging.warning(f"Calculating crc32c checksums with {num_threads} threads")
	start = datetime.datetime.now()
	with concurrent.futures.ThreadPoolExecutor(num_threads) as executor:	
		futures = [executor.submit(calculate_crc32c, row) for key, row in od.items()]
		print("Executing total", len(futures), "jobs")

		for idx, future in enumerate(concurrent.futures.as_completed(futures)):
			try:
				res = future.result()
			except ValueError as e:
				print(e)
	end = datetime.datetime.now()
	print('Elapsed time for crc32c checksums:', end - start)

def calculate_crc32c(row):
	if (row['file_crc32c'] != ''):
		# already have value. don't need to compute
		return

	file_path = row['file_name']
	if ('intermediate_file_name' in row and row['intermediate_file_name'] != ''):
		file_path = row['intermediate_file_name']

	if (file_path.startswith('gs://') or file_path.startswith('s3://')):
		# only calculate checksum if we have a localfile
		return
	print("Calculating crc32c for ", file_path)
	start = datetime.datetime.now()			
	crc32c = crcmod.predefined.Crc('crc-32c')
	with open(file_path, 'rb') as fp:
		while True:
			data = fp.read(8192)
			if not data:
				break
			crc32c.update(data)
	end = datetime.datetime.now()
	base64_value = base64.b64encode(crc32c.digest()).decode('utf-8')
	print('Elapsed time for checksum:', crc32c.crcValue, base64_value, end - start)
	row['file_crc32c'] = base64_value

def calculate_md5sum_threaded(od, num_threads):
	print('Calculating md5 checksums with', num_threads, 'threads')
	start = datetime.datetime.now()
	with concurrent.futures.ThreadPoolExecutor(num_threads) as executor:	
		futures = [executor.submit(calculate_md5sum, row) for key, row in od.items()]
		print("Executing total", len(futures), "jobs")

		for idx, future in enumerate(concurrent.futures.as_completed(futures)):
			try:
				res = future.result()
			except ValueError as e:
				print(e)
	end = datetime.datetime.now()
	print(f"Elapsed time for md5 checksums (calculate_md5sum_threaded): {end - start}")
	
def calculate_md5sum(row):
	if (row['md5sum'] != ''):
		# already have value. don't need to compute
		return

	file_path = row['file_name']
	if ('intermediate_file_name' in row and row['intermediate_file_name'] != ''):
		file_path = row['intermediate_file_name']

	if (file_path.startswith('gs://') or file_path.startswith('s3://')):
		# only calculate checksum if we have a localfile
		return
	
	print(f"Calculating md5sum for {file_path}")

	m = hashlib.md5()
	with open(file_path, 'rb') as fp:
		while True:
			data = fp.read(8192)
			if not data:
				break
			m.update(data)

	row['md5sum'] = m.hexdigest()

# manifest_keys are used to add additional keys to the manifest

def generate_dict_from_input_manifest_file(input_manifest_file, manifest_keys):
	print(f"input_manifest_file: {input_manifest_file.name}")
	od = OrderedDict()
		
	reader = csv.DictReader(input_manifest_file, dialect='excel-tab')
	for row in reader:
		print(row)
		od[row['file_name']] = row
		if (manifest_keys):
			for manifest_key in manifest_keys:
				if (manifest_key not in row):
					row[manifest_key] = ''
	return od

def generate_dict_from_file_directory(file_directory, study_id, consent_group, manifest_keys):
	od = OrderedDict()

	# r=root, d=directories, f = files
	for r, d, f in os.walk(file_directory):
		for file in f:
			file_path = os.path.join(r, file)
			row = get_file_metadata_for_file_path(file_path, study_id, consent_group)
			od[row['file_name']] = row
			row['input_file_path'] = row['file_name']
			if (manifest_keys):
				for manifest_key in manifest_keys:
					if (manifest_key not in row):
						row[manifest_key] = ''

	# sort by file name
	od = OrderedDict(sorted(od.items(), key=lambda x: x[1]['file_name']))
	return od

def update_manifest_file(f, od):
	with threading.Lock():
		# start from beginning of file
		f.seek(0)
		f.truncate()
	
		isfirstrow = True
		tsv_writer = csv.writer(f, delimiter='\t')
		for key, row in od.items():
			if (isfirstrow):
				# print header row
				tsv_writer.writerow(row.keys())
				isfirstrow = False 
			tsv_writer.writerow(row.values())
	print(f"update_manifest_file - done")
	# we don't close the file until the end of the operation		

def get_bucket_and_key_for_cloud_url(cloud_url):
	o = urlparse(cloud_url, allow_fragments=False)
	return (o.netloc, o.path.lstrip('/'))

def remove_file_types_from_dict(od, file_types):
	keys_to_delete = []
		
	for key, row in od.items():
		file_type= row['file_type']
		if (file_type in file_types):
			keys_to_delete.append(key)
		
	for key in keys_to_delete:
		del od[key]

def calculate_md5um_for_cloud_paths(od):
	for key, row in od.items():
		if (row['md5sum'] == ''):
			calculate_md5sum_for_cloud_path(row)

def calculate_md5sum_for_cloud_paths_threaded(od, num_threads):
	# print(f"Calculating cloud md5 checksums with {num_threads} threads")
	start = datetime.datetime.now()
	with concurrent.futures.ThreadPoolExecutor(num_threads) as executor:	
		futures = [executor.submit(calculate_md5sum_for_cloud_path, row) for key, row in od.items()]
		print("Executing total", len(futures), "jobs")

		for idx, future in enumerate(concurrent.futures.as_completed(futures)):
			try:
				res = future.result()
			except ValueError as e:
				print(e)
	end = datetime.datetime.now()
	# print('Elapsed time for md5 checksums:', end - start)
	print(f"Elapsed time for md5 checksums (calculate_md5sum_for_cloud_paths_threaded): {end - start}")

def calculate_md5sum_for_cloud_path(row):
	if ('md5sum' in row and row['md5sum'] != ''):
		print(f"md5sum exists for {row['file_name']}")
		return

	local_file = row['file_name']
	tmpfilepath = ''
	
	print(f"Calculating md5sum for {row['file_name']}")
	try:	
		if(row['file_name'].startswith("gs://") or row['file_name'].startswith("s3://")):
			(tmpfilepointer, tmpfilepath) = tempfile.mkstemp(None, None, '.', False)
			obj = urlparse(row['file_name'], allow_fragments=False)
#fixme stream file instead. this affects cases where it is gs -> gs or s3 -> s3 and the md5sum is not stored on server		
			if(local_file.startswith("gs://")):						
				download_gs_key(obj.netloc, obj.path.lstrip('/'), tmpfilepath)
				local_file = tmpfilepath
			elif(local_file.startswith("s3://")):
				download_aws_key(obj.netloc, obj.path.lstrip('/'), tmpfilepath)
				local_file = tmpfilepath
		if (isfile(local_file) and access(local_file, R_OK)):
			m = hashlib.md5()
			with open(local_file, 'rb') as fp:
				while True:
					data = fp.read(65536)
					if not data:
						break
					m.update(data)
		else:
			print("Not a valid path in calculate_md5sum: ", row['file_name'])	
			return
	finally:
		if (tmpfilepath):
			# remove temp file
			os.remove(tmpfilepath)
		
	row['md5sum'] = m.hexdigest()


		
# Given a gs:// path, download it to download_path_name

def download_gs_key(bucket_name, key, download_path_name):
	subprocess.check_call([
		'gsutil',
		'-o', 'GSUtil:parallel_composite_upload_threshold=%s' % ('150M'),
		'cp', 'gs://%s/%s' % (bucket_name, key), download_path_name
	])
	print('downloaded gs://%s/%s to %s' % (bucket_name, key, download_path_name))

# Given an s3:// path, download it to download_path_name

def download_aws_key(bucket_name, key, download_path_name):
	# sess = boto3.session.Session(
	# 	aws_access_key_id='YOUR_KEY',
    # 	aws_secret_access_key='YOUR_SECRET'
	# )
	sess = boto3.session.Session()
	s3 = sess.client("s3")
#	s3 = boto3.client('s3')
	s3.download_file(bucket_name, key, download_path_name)
	print('downloaded s3://%s/%s to %s' % (bucket_name, key, download_path_name))
	
def generate_ordered_dict_for_updated_files(od):
	updated_od = OrderedDict()
	for key, row in od.items():
		if (row['input_file_path'].startswith("*M*")):
			row['input_file_path'] = row['input_file_path'].strip("*M*")
			row['md5sum'] = ""
			row['gs_crc32c'] = ""
			updated_od[key] = row
			print("UPDATED", updated_od)

	return updated_od		

def get_gcloud_checksums_and_metadata_for_dict(od, threads, bucket_name):
	storage_client = storage.Client()
	bucket = storage_client.bucket(bucket_name)

	with concurrent.futures.ThreadPoolExecutor(threads) as executor:
		futures = [executor.submit(get_gcloud_checksums_and_metadata, value, bucket) for key, value in od.items()]
		print("Executing total", len(futures), "jobs with", threads, "threads")
		# logging.warning(f"Executing total {len(futures)} jobs with {threads} threads")
		for idx, future in enumerate(concurrent.futures.as_completed(futures)):
			try:
				res = future.result()
#				print("Processed job", idx, "result", res)	
			except ValueError as e:
				print(e)

def get_gcloud_checksums_and_metadata(value, bucket):
	strip_prefix = "gs://" + bucket.name
#	strip_prefix = ''
	path = value['gs_path'].lstrip(strip_prefix)
	print('path', path)	
	blob = bucket.get_blob(path)
	if ((blob is not None) and blob.exists()):
		blob.reload()
		value['gs_crc32c'] = blob.crc32c
		add_gs_manifest_metadata(value, blob, path, value['input_file_path'])
	else: 
		print("Blob does not exist:", path)

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
				if (file_path.startswith('gs://') or file_path.startswith('s3://')):
					md5sum = calculate_md5sum_for_cloud_path(input_file_path)
					fields['md5sum'] = md5sum
				else:
					md5sum = calculate_md5sum(input_file_path)
					fields['md5sum'] = md5sum	
		if (not fields['ga4gh_drs_uri'].startswith("drs://")):
# FIXME	
#			add_drs_uri_from_path(fields, gs_path)
			add_new_drs_uri(fields)