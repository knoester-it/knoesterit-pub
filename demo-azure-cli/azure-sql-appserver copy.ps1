<#
	=======================================================================================================
     Created on:   	28/04/2021 21:50
	 Created by:   	Robert Knoester
	 Organization: 	Knoester-IT Solutions

     This script creates windows application server(s) and default Azure SQL server for hosting Azure SQL 
     databases:

        - Create Resource group
        - Create SQL Server instance
        - Set connection policy
        - Add AAD admins for sql server
        - Create first database
        - Create Azure SQL server level based firewall rules (when configured with public access enabled)
        - Create private DNS zone
        - Create private link / endpoint
        - Create app server(s)
        - Edit NSG outbound rule (deny from any to SQL instance (because of private link usage)
        - Edit NSG outbound rule with allow from appserver(s)
        - Create storage for SQL migration path (account + conatainer for blob)
        - Create Azure file share
     =======================================================================================================
Changes after review:
  ## Create private-dns-link
  --name $vnet.name (corrected from -- name $vnet)

Websites used:
https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-cli
https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming

TODO

#>
$random = Get-Random -Minimum 100 -Maximum 200
$random_priority_deny = Get-Random -Minimum 400 -Maximum 500
$app_name = "bla"
$env = "pr" # Environment : np = non-production, pr = production
$zone_sql = "snet-backend" # Azure SQL network location
$public_access = "false" # Allow public access : true or false
$vmpublic_ip = "true" # Assign public ip : true or false
$resourceGroup = "rg-$env-$app_name"
$sql_server = "sql-$app_name-$random-$env"
$location = "East US"
$subscription = az account show --query id -o tsv
$myadminuser = "adminfor-sql"
$myadminpassword = az keyvault secret show --name "SQL-admin" --vault-name "kv-4test" --query value -o tsv
$aad_admins = "HelpdeskAgents"
$connection_policy = "Redirect"
$db_name = "sqldb-$app_name-$env"
$appservers = "vm-$app_name-01-$env","vm-$app_name-02-$env"
$zone_appservers = "snet-frontend" # Appserver network location : frontend, backend
$az_files = "Yes"
$az_files_quota = "10" # if $az_files = "Yes"; you can manage the quota
$rg_vnet = "rg-vnet-spoke-001" #vnet can be in other resource group; if so specify otherwise : $resourceGroup
$vnetname = "vNet-spoke-001"
$available_zones = "nsg-frontend","nsg-backend" # >>>> Moet aangepast worden voor NSG en $env toevoegen
$private_dns_zone = "privatelink.database.windows.net"

# Connect-Azuread before running this script (this is for mappaing AzureAD admins to SQL)

#START Create Azure SQL server

#Create resource group
echo "Creating $resourceGroup in "$location"..."
az group create -l "$location" -n $resourceGroup --tags $tag

##Create a sql server
az sql server create -l "$location" -g $resourceGroup -n $sql_server  -u $myadminuser -p $myadminpassword --minimal-tls-version 1.2 --subscription $subscription
## Add AAD admin on Azure SQL server
$group_id = Get-AzureADGroup -SearchString $aad_admins | Select ObjectID -ExpandProperty ObjectID
az sql server ad-admin create -u $aad_admins -i $group_id -g $resourceGroup -s $sql_server --subscription $subscription
## Set Azure SQL Server connection policy
az sql server conn-policy update -g $resourceGroup -s $sql_server --connection-type $connection_policy --subscription $subscription
#END Create Azure SQL server

#START Create app servers
## Create app server interfaces
if($vmpublic_ip -eq "true" )
{
Foreach ($appserver in $appservers)
{
   $vnet = Get-AzVirtualNetwork -Name "$vnetname"
   $subnet = Get-AzVirtualNetworkSubnetConfig -Name "$zone_appservers" -VirtualNetwork $vnet
#Standard SKU for prod and basic for non-prod  
   if($env -eq "np" )
   {
   az network public-ip create -g $resourceGroup -n "pip-$appserver" --allocation-method Static --sku Basic      
   }
   else 
   {
   az network public-ip create -g $resourceGroup -n "pip-$appserver" --allocation-method Static --sku Standard
   }
   az network nic create -g $resourceGroup --subnet $subnet.id -n "$appserver" --public-ip-address "pip-$appserver"
   az vm create -g "$resourceGroup" --name "$appserver" --image "win2019datacenter" --size Standard_B2s --admin-username "$myadminuser" --admin-password "$myadminpassword" --nics "$appserver"
}
}
else 
{
   $vnet = Get-AzVirtualNetwork -Name "$vnetname"
   $subnet = Get-AzVirtualNetworkSubnetConfig -Name "$zone_appservers" -VirtualNetwork $vnet
   az network nic create -g $resourceGroup --subnet $subnet.id -n "$appserver"
   az vm create -g "$resourceGroup" --name "$appserver" --image "win2019datacenter" --size Standard_B2s --admin-username "$myadminuser" --admin-password "$myadminpassword" --nics "$appserver" --public-ip-address """"
}

#END  app server interfaces

#START Create databases
## Create database
New-AzSqlDatabase -ResourceGroupName $resourceGroup -ServerName $sql_server -DatabaseName $db_name -Edition "GeneralPurpose" -Vcore 2 -ComputeGeneration "Gen5" -ComputeModel Serverless
## Set short term retention to 35 days
Set-AzSqlDatabaseBackupShortTermRetentionPolicy -ResourceGroupName $resourceGroup -ServerName $sql_server -DatabaseName $db_name -RetentionDays 35 # Automated backups https://docs.microsoft.com/en-us/azure/azure-sql/database/automated-backups-overview
#END Create databases

#START Setup Connectivity
if($public_access -eq "true" )
{
   ## Set SQL server level firewall rules
   Foreach ($appserver in $appservers)
   {
      $ip = Get-AzNetworkInterface -ResourceGroupName "$resourceGroup" -name $appserver
      New-AzSqlServerFirewallRule -ResourceGroupName "$resourceGroup" -ServerName $sql_server -FirewallRuleName "allow_$appserver" -StartIpAddress $ip.IpConfigurations.PrivateIpAddress -EndIpAddress $ip.IpConfigurations.PrivateIpAddress
   }
}
else 
{
   write-host("No rules applicable with public access disabled")
}

## Disable/Enable public access
## With disabled public access to server
if($public_access -eq "false" )
{
## CHECK   ## Create Azure private dns zone for private link
   $privatednsexist = Get-AzPrivateDnsZone -ResourceGroupName $rg_vnet
   if($privatednsexist.name -eq "privatelink.database.windows.net" )
   {
      write-host("privatelink.database.windows.net already exists")      
   }
   else 
   {
      New-AzPrivateDnsZone -Name $private_dns_zone -ResourceGroupName $rg_vnet # https://docs.microsoft.com/en-us/azure/dns/private-dns-getstarted-powershell}
   }
   ## Create Azure SQL server private link
   az network vnet subnet update --name $zone_sql --resource-group $rg_vnet --vnet-name $vnetname --disable-private-endpoint-network-policies true # https://docs.microsoft.com/en-us/azure/private-link/disable-private-endpoint-network-policy
   $vnet = Get-AzVirtualNetwork -Name "$vnetname"
   $subnet_sql = Get-AzVirtualNetworkSubnetConfig -Name "$zone_sql" -VirtualNetwork $vnet
   $sqlserver_id = Get-AzureRmSqlServer -ResourceGroupName $resourceGroup -server $sql_server
   az network private-endpoint create --name $env-$app_name-SQL --resource-group $resourceGroup --group-id sqlServer --subnet $subnet_sql.id --private-connection-resource-id $sqlserver_id.ResourceId --connection-name $env-$app_name-SQL
   ## Create private-dns-link
   az network private-dns link vnet create --name $vnet.name --registration-enabled true --resource-group $rg_vnet --subscription $subscription --virtual-network $vnet.id --zone-name $private_dns_zone
      
   ## Create outbound NSG rules
   ## Define private endpoint variables 
   $privateEndpoint_interface =  Get-AzPrivateEndpoint -name $env-$app_name-SQL -ResourceGroupName $resourceGroup
   $ip_privateEndpoint = Get-AzNetworkInterface -ResourceId $privateEndpoint_interface.NetworkInterfaces.Id

   ## Deny from any to SQL instance (because of private link usage)
   Foreach ($available_zone in $available_zones)
   {
      Get-AzNetworkSecurityGroup -Name "$available_zone" -ResourceGroupName "$rg_vnet" |
      Add-AzNetworkSecurityRuleConfig -Name "Deny_to_$sql_server" -Description "Deny_to_$sql_server" -Access "Deny" -Protocol "*" -Direction "Outbound" -Priority "$random_priority_deny" -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix  $ip_privateEndpoint.IpConfigurations.PrivateIpAddress -DestinationPortRange "1433" |
      Set-AzNetworkSecurityGroup
   }
   ## Disable puclic network access
   az sql server update -g $resourceGroup -n $sql_server --enable-public-network false
## CHECK   ## Create DNS registration of private endpoint
   New-AzPrivateDnsRecordSet -Name $sql_server -RecordType A -ZoneName $private_dns_zone -ResourceGroupName $rg_vnet -Ttl 10 -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address $ip_privateEndpoint.IpConfigurations.PrivateIpAddress)
   
   ## NSG Allow rule for appserver(s) to allow SQL traffic
   Foreach ($appserver in $appservers)
   {
      $random_priority_allow = Get-Random -Minimum 300 -Maximum 399
      $ip = Get-AzNetworkInterface -ResourceGroupName "$resourceGroup" -name $appserver
      Get-AzNetworkSecurityGroup -Name "nsg-frontend" -ResourceGroupName "$rg_vnet" |
      Add-AzNetworkSecurityRuleConfig -Name "Allow_$appserver" -Description "Allow_to_$sql_server from $appserver" -Access "Allow" -Protocol "*" -Direction "Outbound" -Priority "$random_priority_allow" -SourceAddressPrefix $ip.IpConfigurations.PrivateIpAddress -SourcePortRange "*" -DestinationAddressPrefix  $ip_privateEndpoint.IpConfigurations.PrivateIpAddress -DestinationPortRange "1433" |
      Set-AzNetworkSecurityGroup
   }

<## CHECK Add source
   Get-AzNetworkSecurityGroup -Name "nsg-frontend" -ResourceGroupName "$rg_vnet" |
   Add-AzNetworkSecurityRuleConfig -Name "Allow_to_$sql_server" -Description "Allow_to_$sql_server" -Access "Allow" -Protocol "*" -Direction "Outbound" -Priority "$random_priority_allow" -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix  $ip_privateEndpoint.IpConfigurations.PrivateIpAddress -DestinationPortRange "1433" |
   Set-AzNetworkSecurityGroup
   #>
}
else 
{
## with enabled public access to server
   write-host("Public access already set")
}

#END Setup Connectivity

# START Create storage 
# For SQL migration path
az storage account create --name "st$app_name$random".ToLower() --resource-group $resourceGroup --location "$location" --sku Standard_RAGRS --kind StorageV2
az storage container create --account-name "st$app_name$random".ToLower() --name "sqlmigrate$app_name".ToLower()

# For Azure files share
If ("$az_files" -eq "Yes") 
{
   az storage share-rm create --resource-group $resourceGroup --storage-account "st$app_name$random".ToLower() --name "fs$app_name$random".ToLower() --quota $az_files_quota
}
else 
{
   write-host("No Azure files needed for configuration")
}

#END Setup Create storage