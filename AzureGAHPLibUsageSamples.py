import sys

def read_credentials_from_file(fileName):
        dnary = dict()
        with open(fileName, 'r') as f:
            for line in f:
                if not line.strip():
                   continue
                nvp = line.split(" ")
                if(not nvp):
                    return None
                if(len(nvp) < 2):
                    return None
                nvp[0] = nvp[0].strip()
                nvp[1] = nvp[1].strip()
                if((len(nvp[0]) < 1) or (len(nvp[1]) < 1)):
                    return None
                dnary[nvp[0]] = nvp[1]
        return dnary        

def create_service_credentials(dnary):
        write_message('creating credentials\r\n')
        credentials = ServicePrincipalCredentials(client_id = dnary["client_id"], secret = dnary["secret"], tenant = dnary["tenant_id"])
        return credentials

def create_credentials_from_file(fileName):
        dnary = read_credentials_from_file(fileName)
        cred = create_service_credentials(dnary)
        write_message("credentials created\r\n")
        return cred

def create_client_libraries(credentials, subscription_id):
        print('creating client libraries ' + subscription_id + "\r\n")
        compute_client = ComputeManagementClient(
            credentials,
            subscription_id
        )
        network_client = NetworkManagementClient(
            credentials,
            subscription_id
        )
        resource_client = ResourceManagementClient(
            credentials,
            subscription_id
        )
        storage_client = StorageManagementClient(
            credentials,
            subscription_id
        )

        client_libs = {
            'compute_client': compute_client,
            'network_client': network_client,
            'resource_client': resource_client,
            'storage_client': storage_client}

        print('creating client libraries: complete' + "\r\n")
        return client_libs
def sample_create_client_libraries(credentials, ce):
    subscription_id = '3851e781-e545-43e9-a0c5-c4b42aab2fe5'
    return create_client_libraries(credentials, subscription_id)

def sample_create_credentials(ce):
    return create_credentials_from_file("C:/DDR/python/PythonApplication1/PythonApplication1/AppSettings.txt")

def sample_create_vm(ce):
    credentials = sample_create_credentials()
    client_libs = sample_create_client_libraries(credentials)
    compute_client = client_libs['compute_client']
    network_client = client_libs['network_client']
    resource_client = client_libs['resource_client']
    storage_client = client_libs['storage_client']
    
    location = 'westus'
    groupName = 'aa1rangasrg'
    vnetName = 'aa1rangasvnet'
    subnetName = 'aa1rangassubnet'
    osDiskName = 'aa1rangasosdisk'
    storageAccountName = 'aa1rangassa'
    ipConfigName = 'aa1rangasipconfig'
    nicName = 'aa1rangasnic'
    userName = 'rangas'
    password = 'tEst1234!@#$'
    vmName = 'aah'
    size = 'Standard_DS1'
    vmRef = {
        'linux1': {
            'publisher': 'Canonical',
            'offer': 'UbuntuServer',
            'sku': '16.04.0-LTS',
            'version': 'latest'
        },
        'windows': {
            'publisher': 'MicrosoftWindowsServerEssentials',
            'offer': 'WindowsServerEssentials',
            'sku': 'WindowsServerEssentials',
            'version': 'latest'
        }
    }

    ce.create_vm(compute_client, network_client, resource_client, storage_client, location, groupName, vnetName, subnetName, osDiskName, storageAccountName, ipConfigName, nicName, userName, password, vmName, size, vmRef)


def sample_delete_vm(ce):
    vmName = 'aa1rangasvm'
    groupName = 'aa1rangasrg'
    credentials = sample_create_credentials()
    client_libs = sample_create_client_libraries(credentials)
    compute_client = client_libs['compute_client']
    ce.delete_vm(compute_client, groupName, vmName)

def sample_delete_rg(ce):
    groupName = 'aa1rangasrg'
    credentials = sample_create_credentials()
    client_libs = sample_create_client_libraries(credentials)
    resource_client = client_libs['resource_client']
    ce.delete_rg(resource_client, groupName)    
