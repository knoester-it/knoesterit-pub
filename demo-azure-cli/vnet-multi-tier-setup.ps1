# https://docs.microsoft.com/en-us/azure/virtual-network/scripts/virtual-network-cli-sample-multi-tier-application
# Create vNet for multi-tier application

# Variable block
$location="East US"
$resourceGroup="demo-vnet-rg"
$tag="virtual-network-multi-tier-application"
$vNet="demo-vNet"
$addressPrefixVNet="10.0.0.0/16"
$subnetFrontEnd="frontend-subnet"
$subnetPrefixFrontEnd="10.0.1.0/24"
$nsgFrontEnd="nsg-frontend"
$subnetBackEnd="backend-subnet"
$subnetPrefixBackEnd="10.0.2.0/24"
$nsgBackEnd="nsg-backend"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a virtual network and a front-end subnet.
echo "Creating $vNet and $subnetFrontEnd"
az network vnet create --resource-group $resourceGroup --name $vNet --address-prefix $addressPrefixVNet  --location "$location" --subnet-name $subnetFrontEnd --subnet-prefix $subnetPrefixFrontEnd

# Create a backend subnet.
echo "Creating $subnetBackEnd"
az network vnet subnet create --address-prefix $subnetPrefixBackEnd --name $subnetBackEnd --resource-group $resourceGroup --vnet-name $vNet

# Create a network security group (NSG) for the front-end subnet.
echo "Creating $nsgFrontEnd for $subnetFrontEnd"
az network nsg create --resource-group $resourceGroup --name $nsgFrontEnd --location "$location"

# Create NSG rules to allow HTTP & HTTPS traffic inbound.
echo "Creating $nsgFrontEnd rules in $nsgFrontEnd to allow HTTP and HTTPS inbound traffic"
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgFrontEnd --name Allow-HTTP-All --access Allow --protocol Tcp --direction Inbound --priority 100 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 80
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgFrontEnd --name Allow-HTTPS-All --access Allow --protocol Tcp --direction Inbound --priority 200 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 443

# Create an NSG rule to allow SSH traffic in from the Internet to the front-end subnet.
echo "Creating NSG rule in $nsgFrontEnd to allow inbound SSH traffic"
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgFrontEnd --name Allow-SSH-All --access Allow --protocol Tcp --direction Inbound --priority 300 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 22

# Associate the front-end NSG to the front-end subnet.
echo "Associate $nsgFrontEnd to $subnetFrontEnd"
az network vnet subnet update --vnet-name $vNet --name $subnetFrontEnd --resource-group $resourceGroup --network-security-group $nsgFrontEnd

# Create a network security group for the backend subnet.
echo "Creating $nsgBackEnd for $subnetBackEnd"
az network nsg create --resource-group $resourceGroup --name $nsgBackEnd --location "$location"

# Create an NSG rule to allow MySQL traffic from the front-end subnet to the backend subnet.
echo "Creating NSG rule in $nsgBackEnd to allow MySQL traffic from $subnetFrontEnd to $subnetBackEnd"
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgBackEnd --name Allow-MySql-FrontEnd --access Allow --protocol Tcp --direction Inbound --priority 100 --source-address-prefix $subnetPrefixFrontEnd --source-port-range "*" --destination-address-prefix "*" --destination-port-range 3306

# Create an NSG rule to allow SSH traffic from the Internet to the backend subnet.
echo "Creating NSG rule in $nsgBackEnd to allow SSH traffic from the Internet to $subnetBackEnd"
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgBackEnd --name Allow-SSH-All --access Allow --protocol Tcp --direction Inbound --priority 200 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 22

# Create an NSG rule to block all outbound traffic from the backend subnet to the Internet (NOTE: If you run the MySQL installation below this rule will be disabled and then re-enabled).
echo "Creating NSG rule in $nsgBackEnd to block all outbound traffic from $subnetBackEnd"
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgBackEnd --name Deny-Internet-All --access Deny --protocol Tcp --direction Outbound --priority 300 --source-address-prefix "*" --source-port-range "*" --destination-address-prefix "*" --destination-port-range "*"

# Associate the backend NSG to the backend subnet.
echo "Associate $nsgBackEnd to $subnetBackEnd"
az network vnet subnet update --vnet-name $vNet --name $subnetBackEnd --resource-group $resourceGroup --network-security-group $nsgBackEnd