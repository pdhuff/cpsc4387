import googleapiclient.discovery
from google.cloud import runtimeconfig


def cloud_fn_stop_all_servers(event, context):
    """
    Simply stops all servers in the project. This is meant to run periodically to prevent servers from running
    constantly
    :param event: No data is passed to this function
    :param context: No data is passed to this function
    :return:
    """
    runtimeconfig_client = runtimeconfig.Client()
    myconfig = runtimeconfig_client.config('cybergym')
    project = myconfig.get_variable('project').value.decode("utf-8")
    region = myconfig.get_variable('region').value.decode("utf-8")
    zone = myconfig.get_variable('zone').value.decode("utf-8")

    compute = googleapiclient.discovery.build('compute', 'v1')
    result = compute.instances().list(project=project, zone=zone).execute()
    if 'items' in result:
        for vm_instance in result['items']:
            compute.instances().stop(project=project, zone=zone, instance=vm_instance["name"]).execute()
