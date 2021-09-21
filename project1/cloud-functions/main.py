import uuid
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
    zone = myconfig.get_variable('zone').value.decode("utf-8")

    compute = googleapiclient.discovery.build('compute', 'v1')
    result = compute.instances().list(project=project, zone=zone).execute()
    if 'items' in result:
        for vm_instance in result['items']:
            compute.instances().stop(project=project, zone=zone, instance=vm_instance["name"]).execute()


def cloud_fn_your_cloud_function(event, context):
    """
    This is your function
    Args:
         event (dict):  The dictionary with data specific to this type of
         event. The `data` field contains the PubsubMessage message. The
         `attributes` field will contain custom attributes if there are any.
         context (google.cloud.functions.Context): The Cloud Functions event
         metadata. The `event_id` field contains the Pub/Sub message ID. The
         `timestamp` field contains the publish time.
    Returns:
        A success status
    """

    action = event['attributes']['action'] if 'action' in event['attributes'] else None

    if not action:
        print(f'No action provided in cloud_fn_manage_server for published message.')
        return

    if action == "build":
        runtimeconfig_client = runtimeconfig.Client()
        myconfig = runtimeconfig_client.config('cybergym')
        project = myconfig.get_variable('project').value.decode("utf-8")
        zone = myconfig.get_variable('zone').value.decode("utf-8")

        server_name = f"auto_server-{uuid.uuid4()}"
        compute = googleapiclient.discovery.build('compute', 'v1')
        image_response = compute.images().getFromFamily(project="debian-cloud", family="debian-9").execute()
        source_disk_image = image_response["selfLink"]
        config = {
            "name": server_name,
            "machineType": f"projects/{project}/zones/{zone}/machineTypes/e2-micro",
            "disks": [
                {
                    "boot": True,
                    "autoDelete": True,
                    "initializeParams": {
                        "sourceImage": source_disk_image,
                    }
                }
            ],
            "networkInterfaces": [{
                "network": "global/networks/default",
                "accessConfigs": [
                    {"type": "ONE_TO_ONE_NAT", "name": "External NAT"}
                ]
            }],
        }
        print("Continue coding to deploy the server")
    elif action == "bucket":
        print("Replace this with a function to create the cloud bucket.")
