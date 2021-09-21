from main import cloud_fn_stop_all_servers, cloud_fn_your_cloud_function


def test_locally():
    # Add any local functions for testing. Use the local_event structure to simulate the PubSub message.
    local_event = {
        'attributes': {
            'action': "build"
        }
    }
    cloud_fn_your_cloud_function(local_event, None)


if __name__ == '__main__':
    test_locally()
