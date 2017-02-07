#!/usr/bin/python

import json
import sys
import getopt


try:
	options, extra_args = getopt.getopt(sys.argv[1:], 'hvd:o:')
except getopt.GetoptError as err:
	print err
	sys.exit(1)

file_name = extra_args[0] if len(extra_args)>0 else None
#print "options :"
#print options
#print "extra_args :"
#print extra_args
#print "filename :"
#print file_name


verbose = False
debug = False


def usage() :

	print "Help : ....TODO"


def removeFields ( json_object, fields_names, parent=None ) :

	if verbose :
		print "removing in '%s'" % ( parent if parent else '<root>' )

	removed_fields = []
	for attribute, value in json_object.iteritems():
		if attribute.startswith('__'):
			continue
		for field_name in fields_names :
			absolute_attribute = parent+"."+attribute if parent else attribute
			if absolute_attribute == field_name :
				removed_fields.append ( attribute )
			else :
				attribute_object = json_object[attribute]
				if type(attribute_object) is dict :
					if field_name.startswith ( absolute_attribute ) :
						removeFields ( attribute_object, fields_names, absolute_attribute )

	for removed_field in removed_fields:
		json_object.pop(removed_field)



if __name__ == "__main__" :


	if file_name :
		input_file = open(file_name)
	else :
		input_file = sys.stdin

	output_file = sys.stdout

	operation_to_remove = None


	try :

		obj  = json.load(input_file)

		for o, a in options :
			if o == "-v" :
				if verbose :
					debug = True
				else :
					verbose = True
			elif o in ("-h", "--help") :
				usage()
				sys.exit()
			elif o in ("-d", "--delete") :
				operation_to_remove = a.split(",")
			elif o in ("-o", "--output") :
				output_file = open(a, "w")
			else:
				assert False, "unhandled option"

		if operation_to_remove :
			if verbose :
				print "removing " + ",".join(operation_to_remove)
			removeFields ( obj, operation_to_remove )


		try :
			output_file.write ( json.dumps(obj, sort_keys=True, indent=4, separators=(',', ': ')) )
			output_file.write ( "\n" )
		finally :
			if output_file is not sys.stdin:
				output_file.close()


	finally :
		if input_file is not sys.stdin :
			input_file.close()


