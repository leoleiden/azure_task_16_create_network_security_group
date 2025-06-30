# Ensure you are logged in to Azure: Connect-AzAccount

# --- Variables ---
$resourceGroupName = "mate-azure-task-15" # As per requirement for VNet deployment
$location = "EastUS" # You can choose a different location if desired
$vnetName = "todoapp" # As per requirement
$vnetAddressPrefix = "10.20.30.0/24"

# Subnet configurations (calculated to fit up to 50 VMs, requires /26 prefix)
$webserversSubnetName = "webservers"
$webserversSubnetPrefix = "10.20.30.0/26"

$databaseSubnetName = "database"
$databaseSubnetPrefix = "10.20.30.64/26"

$managementSubnetName = "management"
$managementSubnetPrefix = "10.20.30.128/26"

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

# --- Create Subnet Configurations ---
Write-Host "Configuring subnets..."
$webserversSubnet = New-AzVirtualNetworkSubnetConfig -Name $webserversSubnetName `
    -AddressPrefix $webserversSubnetPrefix

$databaseSubnet = New-AzVirtualNetworkSubnetConfig -Name $databaseSubnetName `
    -AddressPrefix $databaseSubnetPrefix

$managementSubnet = New-AzVirtualNetworkSubnetConfig -Name $managementSubnetName `
    -AddressPrefix $managementSubnetPrefix

# --- Create Virtual Network with Subnets ---
Write-Host "Creating Virtual Network '$vnetName' with subnets..."
New-AzVirtualNetwork -Name $vnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $webserversSubnet, $databaseSubnet, $managementSubnet | Out-Null

Write-Host "Virtual Network '$vnetName' and its subnets deployed successfully!"
