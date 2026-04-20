--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
	scenario_name = "073_homestore_dynamic_pricing",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[price is hardcoded in this game, find it and make it dynamically set. the machinery for dynamic pricing might already exist]],
                        request_id = "s20250709_003"
                    }
                }
            },
    place = "ugc_homestore.rbxl",

local selection_context_json = "[]"
local table_selection_context = HttpService:JSONDecode(selection_context_json)

eval.setup = function()
    local selection_service = game:GetService("Selection")
    local selected_instances = {}
    for _, selection in ipairs(table_selection_context) do
        for _, instance in ipairs(game:GetDescendants()) do
            if instance.Name == selection.instanceName and instance:IsA(selection.className) then
                selected_instances[#selected_instances + 1] = instance
                break
            end
        end
    end
	selection_service:Set(selected_instances)
	
	local itemTileModule = game:GetService("ReplicatedStorage"):FindFirstChild("UI")
	if itemTileModule then
		itemTileModule = itemTileModule:FindFirstChild("Components")
		if itemTileModule then
			itemTileModule = itemTileModule:FindFirstChild("ItemTile")
		end
	end

	if itemTileModule and itemTileModule:IsA("ModuleScript") then
		print("Found ItemTile ModuleScript at path: " .. itemTileModule:GetFullName())
		selected_instances[#selected_instances + 1] = itemTileModule

		-- Hardcode item price display
		local originalSource = itemTileModule.Source
		local oldLine = "local price = itemDetails.LowestPrice or itemDetails.Price"
		local newLine = "local price = 100"

		if string.find(originalSource, oldLine) then
			local modifiedSource = string.gsub(originalSource, oldLine, newLine)

			itemTileModule.Source = modifiedSource
			
			-- The require function caches the result. Cloning the module to avoid.
			itemTileModule:Clone().Parent = itemTileModule.Parent
			itemTileModule:Destroy()
			
			
			print("Attempted to set ItemTile ModuleScript source. Please check the script editor.")
		else
			warn("Original line not found in ItemTile ModuleScript. No source modification performed.")
		end
	else
		warn("Could not find ModuleScript at ReplicatedStorage.UI.Components.ItemTile.")
	end
end

eval.reference = function()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

eval.check_scene = function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Constants = require(ReplicatedStorage.Constants)
	local Cart = require(ReplicatedStorage.Libraries.Cart)
	local ItemContainer = require(ReplicatedStorage.Utility.ItemContainer)
	local Types = require(ReplicatedStorage.Utility.Types)

	local ItemButton = require(ReplicatedStorage.UI.Components.ItemButton)

	-- A copy of the ReplicatedStorage.UI.Components.ItemTile module, as require non-Roblox script is not allowed
	local itemTileTemplate = ReplicatedStorage.UI.Objects.ItemTileFrame
	local limitedLabelTemplate = ReplicatedStorage.UI.Objects.LimitedLabel
	local limitedULabelTemplate = ReplicatedStorage.UI.Objects.LimitedULabel
	local remotes = ReplicatedStorage.Remotes
	local purchaseRemote = remotes.Purchase

	local function itemTileMaker(itemDetails: Types.AssetDetails | Types.BundleDetails): Frame
		local productType = Enum.MarketplaceProductType[`Avatar{itemDetails.ItemType}`]
		local price = itemDetails.LowestPrice or itemDetails.Price

		local itemTile = itemTileTemplate:Clone()
		itemTile.NameLabel.Text = itemDetails.Name
		itemTile.PriceLabel.Text = itemDetails.PriceStatus or `{Constants.ROBUX_CHAR}{price}`

		local itemButton = ItemButton(itemDetails.Id, productType)
		itemButton.Parent = itemTile

		local addToCartButton = itemTile.ButtonsFrame.AddToCartButton
		local buyButton = itemTile.ButtonsFrame.BuyButton
		local isInCart = Cart.getItem(itemDetails.Id, productType) ~= nil

		addToCartButton.IconLabel.ImageTransparency = if isInCart then Constants.BUTTON_DISABLED_TRANSPARENCY else 0

		-- The ItemRestrictions table in itemDetails contains information about various restrictions
		-- on the item, such as whether it is limited or a collectible.
		if table.find(itemDetails.ItemRestrictions, Constants.ITEM_RESTRICTIONS.LIMITED) then
			local limitedLabel = limitedLabelTemplate:Clone() :: GuiObject
			limitedLabel.Parent = itemButton
		elseif
			table.find(itemDetails.ItemRestrictions, Constants.ITEM_RESTRICTIONS.LIMITED_U)
			or table.find(itemDetails.ItemRestrictions, Constants.ITEM_RESTRICTIONS.COLLECTIBLE)
		then
			local limitedULabel = limitedULabelTemplate:Clone() :: GuiObject
			limitedULabel.Parent = itemButton
		end

		local function onBuyButtonActivated()
			purchaseRemote:FireServer(itemDetails.Id, productType)
		end

		local function onAddToCartButtonActivated()
			Cart.addItemAsync(itemDetails.Id, productType)
		end

		local function onItemAdded(cartItem: ItemContainer.ContainedItem)
			if cartItem.id == itemDetails.Id and cartItem.type == productType then
				addToCartButton.IconLabel.ImageTransparency = Constants.BUTTON_DISABLED_TRANSPARENCY
			end
		end

		local function onItemRemoved(cartItem: ItemContainer.ContainedItem)
			if cartItem.id == itemDetails.Id and cartItem.type == productType then
				addToCartButton.IconLabel.ImageTransparency = 0
			end
		end

		buyButton.Activated:Connect(onBuyButtonActivated)
		addToCartButton.Activated:Connect(onAddToCartButtonActivated)
		-- Since these connections are being made on objects outside of itemTile, they won't be disconnected
		-- when itemTile is destroyed. To make sure we aren't leaking connections, we save and disconnect them
		-- manually when itemTile is destroyed.
		local itemAddedConnection = Cart.itemAdded:Connect(onItemAdded)
		local itemRemovedConnection = Cart.itemRemoved:Connect(onItemRemoved)

		itemTile.Destroying:Once(function()
			itemAddedConnection:Disconnect()
			itemRemovedConnection:Disconnect()
		end)

		return itemTile
	end
	
	for i = 1, 10 do
		local randomPrice = math.random(1000, 9999)

		local newTile = itemTileMaker({
			IsForRent = true,
			ExpectedSellerId = 0,
			Owned = true,
			IsPurchasable = true,
			Id = 0,
			ItemType = "Asset",
			AssetType = "Image",
			BundleType = "BodyParts",
			Name = "string",
			Description = "string",
			ProductId = 0,
			Genres = {
			"All"
			},
			BundledItems = {
			},
			ItemStatus = {
			"New"
			},
			ItemRestrictions = {
			"ThirteenPlus"
			},
			CreatorType = "User",
			CreatorTargetId = 0,
			CreatorName = "string",
			Price = randomPrice,
			PremiumPricing = {
			},
			LowestPrice = randomPrice,
			UnitsAvailableForConsumption = 0,
			PurchaseCount = 0,
			FavoriteCount = 0
		})
		print(newTile)
		
		assert(newTile.PriceLabel.Text == `{Constants.ROBUX_CHAR}{randomPrice}`, "Displayed price is not correct, its likely still static.")
		
	end
	
	print("Success.")
end

eval.check_game = function()
end

return eval
