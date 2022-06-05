# https://docs.microsoft.com/en-us/azure/virtual-network/scripts/virtual-network-cli-sample-multi-tier-application
# Create vNet for multi-tier application

# Variable block
$location = "East US"
$resourceGroup = "rg-vnet-spoke-001"
$tag = "virtual-network-multi-tier-application"
$vNet = "vNet-spoke-001"
$addressPrefixVNet = "10.0.0.0/16"
$subnetFrontEnd = "snet-frontend"
$subnetPrefixFrontEndPr = "10.0.1.0/24"
$subnetPrefixFrontEndNp = "10.0.2.0/24"
$nsgFrontEnd = "nsg-frontend-pr","nsg-frontend-np"
$subnetBackEnd = "snet-backend"
$subnetPrefixBackEndPr = "10.0.6.0/24"
$subnetPrefixBackEndNp = "10.0.7.0/24"
$nsgBackEnd = "nsg-backend-pr","nsg-backend-np"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a virtual network
echo "Creating $vNet and $subnetFrontEnd"
az network vnet create --resource-group $resourceGroup --name $vNet --address-prefix $addressPrefixVNet  --location "$location"

# Create subnets
echo "Creating subnets"
az network vnet subnet create --address-prefix $subnetPrefixFrontEndPr --name "$subnetFrontEnd-pr" --resource-group $resourceGroup --vnet-name $vNet
az network vnet subnet create --address-prefix $subnetPrefixFrontEndNp --name "$subnetFrontEnd-np" --resource-group $resourceGroup --vnet-name $vNet
az network vnet subnet create --address-prefix $subnetPrefixBackEndPr --name "$subnetBackEnd-pr" --resource-group $resourceGroup --vnet-name $vNet
az network vnet subnet create --address-prefix $subnetPrefixBackEndNp --name "$subnetBackEnd-np" --resource-group $resourceGroup --vnet-name $vNet

# Create a network security group (NSG) for the front-end subnet.
echo "Creating $nsgFrontEnd for $subnetFrontEnd"
Foreach ($nsg in $nsgFrontEnd)
{
    az network nsg create --resource-group $resourceGroup --name $nsg --location "$location"
}

# Associate the front-end NSG to the front-end subnet.
echo "Associate $nsgFrontEnd to $subnetFrontEnd"
az network vnet subnet update --vnet-name $vNet --name "$subnetFrontEnd-pr" --address-prefixes $subnetPrefixFrontEndPr --resource-group $resourceGroup --network-security-group "$nsgFrontEnd-pr"
az network vnet subnet update --vnet-name $vNet --name "$subnetFrontEnd-np" --address-prefixes $subnetPrefixFrontEndNp --resource-group $resourceGroup --network-security-group "$nsgFrontEnd-np"

# Create a network security group for the backend subnet.
echo "Creating $nsgBackEnd for $subnetBackEnd"
Foreach ($nsg in $nsgBackEnd)
{
    az network nsg create --resource-group $resourceGroup --name $nsg --location "$location"
}

# Associate the backend NSG to the backend subnet.
echo "Associate $nsgBackEnd to $subnetBackEnd"
az network vnet subnet update --vnet-name $vNet --name "$subnetBackEnd-pr" --address-prefixes $subnetPrefixBackEndPr --resource-group $resourceGroup --network-security-group "$nsgBackEnd-pr"
az network vnet subnet update --vnet-name $vNet --name "$subnetBackEnd-np" --address-prefixes $subnetPrefixBackEndNp --resource-group $resourceGroup --network-security-group "$nsgBackEnd-np"