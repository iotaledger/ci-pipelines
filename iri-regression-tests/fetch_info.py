from yaml import load, Loader
import argparse
parser = argparse.ArgumentParser()
parser.add_argument('-n', '--node', dest='node_name', required=True)
parser.add_argument('-q', '--host', dest='host', action='store_true')
parser.add_argument('-p', '--port', dest='port', action='store_true')
parser.add_argument('-d', '--podname', dest='podname', action='store_true')

args = parser.parse_args()
node_name = args.node_name

yaml_path = 'output.yml'
stream = open(yaml_path,'r')
yaml_file = load(stream,Loader=Loader)

for key, value in yaml_file['nodes'].items():
    if key == node_name:
      if args.host:
          print("{}".format(yaml_file['nodes'][node_name]['host']))
      if args.port:
          print("{}".format(yaml_file['nodes'][node_name]['ports']['api']))
      if args.podname:
          print("{}".format(yaml_file['nodes'][node_name]['podname']))
