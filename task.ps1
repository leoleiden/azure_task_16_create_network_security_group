# Ensure you are logged in to Azure: Connect-AzAccount

# --- Variables ---
$resourceGroupName = "mate-resources"
$location = "EastUS" # You can choose a different location if desired
$vnetName = "todo-vnet"
$vnetAddressPrefix = "10.0.0.0/16"

# Subnet configurations
$webserversSubnetName = "webservers"
$webserversSubnetPrefix = "10.0.1.0/24"

$databaseSubnetName = "database"
$databaseSubnetPrefix = "10.0.2.0/24"

$managementSubnetName = "management"
$managementSubnetPrefix = "10.0.3.0/24"

# --- Create Resource Group if it doesn't exist ---
Write-Host "Checking for existing resource group '$resourceGroupName'..."
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (-not $resourceGroup) {
    Write-Host "Creating resource group '$resourceGroupName' in '$location'..."
    New-AzResourceGroup -Name $resourceGroupName -Location $location | Out-Null
    Write-Host "Resource group '$resourceGroupName' created."
} else {
    Write-Host "Resource group '$resourceGroupName' already exists."
}

# --- Create Network Security Groups and Rules ---

# Common rule: Allow traffic within the VNet
$vnetAllowRule = New-AzNetworkSecurityRuleConfig -Name "AllowVnetTraffic" `
    -Description "Allow all traffic within the VNet" `
    -Access Allow `
    -Protocol "*" `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix $vnetAddressPrefix `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange "*"

# Webservers NSG
Write-Host "Creating Network Security Group '$webserversSubnetName-nsg' and rules..."
$webserversHttpRule = New-AzNetworkSecurityRuleConfig -Name "AllowHTTP" `
    -Description "Allow HTTP from Internet" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 200 `
    -SourceAddressPrefix Internet `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 80

$webserversHttpsRule = New-AzNetworkSecurityRuleConfig -Name "AllowHTTPS" `
    -Description "Allow HTTPS from Internet" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 210 `
    -SourceAddressPrefix Internet `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 443

$webserversNsg = New-AzNetworkSecurityGroup -Name "$webserversSubnetName-nsg" `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules ($vnetAllowRule, $webserversHttpRule, $webserversHttpsRule)

Write-Host "NSG '$webserversSubnetName-nsg' created."

# Database NSG
Write-Host "Creating Network Security Group '$databaseSubnetName-nsg' and rules..."
# No internet inbound traffic rules are explicitly defined for database.
# Default deny rules will handle this.
$databaseNsg = New-AzNetworkSecurityGroup -Name "$databaseSubnetName-nsg" `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules ($vnetAllowRule)

Write-Host "NSG '$databaseSubnetName-nsg' created."

# Management NSG
Write-Host "Creating Network Security Group '$managementSubnetName-nsg' and rules..."
$managementSshRule = New-AzNetworkSecurityRuleConfig -Name "AllowSSH" `
    -Description "Allow SSH from Internet" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 200 `
    -SourceAddressPrefix Internet `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 22

$managementNsg = New-AzNetworkSecurityGroup -Name "$managementSubnetName-nsg" `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules ($vnetAllowRule, $managementSshRule)

Write-Host "NSG '$managementSubnetName-nsg' created."

# --- Create Virtual Network and Subnets ---
Write-Host "Configuring subnets with NSGs..."
$webserversSubnet = New-AzVirtualNetworkSubnetConfig -Name $webserversSubnetName `
    -AddressPrefix $webserversSubnetPrefix `
    -NetworkSecurityGroup $webserversNsg

$databaseSubnet = New-AzVirtualNetworkSubnetConfig -Name $databaseSubnetName `
    -AddressPrefix $databaseSubnetPrefix `
    -NetworkSecurityGroup $databaseNsg

$managementSubnet = New-AzVirtualNetworkSubnetConfig -Name $managementSubnetName `
    -AddressPrefix $managementSubnetPrefix `
    -NetworkSecurityGroup $managementNsg

Write-Host "Creating or updating Virtual Network '$vnetName' and subnets..."
$vnet = New-AzVirtualNetwork -Name $vnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $webserversSubnet, $databaseSubnet, $managementSubnet

Write-Host "Virtual Network '$vnetName' and subnets with associated NSGs deployed successfully!"
