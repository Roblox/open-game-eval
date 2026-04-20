--!strict
local LoadedCode = game:FindFirstChild("LoadedCode")

if LoadedCode:FindFirstChild("EvalUtils") then
	local types = require(LoadedCode.EvalUtils.types)
	local utils_runs = require(LoadedCode.EvalUtils.utils_runs)
	local utils_he = require(LoadedCode.EvalUtils.utils_he)
	local lib = require(LoadedCode.EvalUtils.lib)
else
	local types = require(game.LoadedCode.types)
end
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

local eval: BaseEval = {
	scenario_name = "117_fnf_enter_game_ui_menu",
	prompt = {
		{
			{
				role = "user",
				content = [[1. Before entering the game, display a menu with:
   - "Play" button that leads to the scene.
   - "Freeplay" button to choose songs (only placeholder).
   - "Exit" button that closes the menu.
2. Add a logo that says "Friday Night Funkin' Roblox"]],
				
			}
		}
	},
	place = "baseplate.rbxl",
	runConfig = {
		serverCheck = nil,
		clientChecks = {},
	}
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

eval.setup = function()
	local selectionService = game:GetService("Selection")
	local selectedInstances = {}
	for _, selection in ipairs(TableSelectionContext) do
		for _, instance in ipairs(game:GetDescendants()) do
			if instance.Name == selection.instanceName and instance:IsA(selection.className) then
				selectedInstances[#selectedInstances + 1] = instance
				break
			end
		end
	end
	selectionService:Set(selectedInstances)
end


eval.reference = function()
	local StarterGui = game:GetService("StarterGui")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")

	-- Create RemoteEvents for button click communication
	local menuEventsFolder = Instance.new("Folder")
	menuEventsFolder.Name = "MenuEvents"
	menuEventsFolder.Parent = ReplicatedStorage

	local playClickedEvent = Instance.new("RemoteEvent")
	playClickedEvent.Name = "PlayClicked"
	playClickedEvent.Parent = menuEventsFolder

	local freeplayClickedEvent = Instance.new("RemoteEvent")
	freeplayClickedEvent.Name = "FreeplayClicked"
	freeplayClickedEvent.Parent = menuEventsFolder

	local exitClickedEvent = Instance.new("RemoteEvent")
	exitClickedEvent.Name = "ExitClicked"
	exitClickedEvent.Parent = menuEventsFolder

	-- Main Menu ScreenGui
	local menuGui = Instance.new("ScreenGui")
	menuGui.Name = "MainMenu"
	menuGui.ResetOnSpawn = false
	menuGui.IgnoreGuiInset = true
	menuGui.Parent = StarterGui

	-- Background frame to cover screen
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.Position = UDim2.new(0, 0, 0, 0)
	background.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	background.BorderSizePixel = 0
	background.Parent = menuGui

	-- Logo logic here
	local logo = Instance.new("TextLabel")
	logo.Name = "Logo"
	logo.Size = UDim2.new(0, 600, 0, 80)
	logo.Position = UDim2.new(0.5, -300, 0.15, 0)
	logo.BackgroundTransparency = 1
	logo.Text = "Friday Night Funkin' Roblox"
	logo.TextColor3 = Color3.fromRGB(255, 100, 200)
	logo.TextSize = 48
	logo.Font = Enum.Font.GothamBold
	logo.Parent = background

	-- Menu container here
	local menuFrame = Instance.new("Frame")
	menuFrame.Name = "MenuFrame"
	menuFrame.Size = UDim2.new(0, 300, 0, 250)
	menuFrame.Position = UDim2.new(0.5, -150, 0.4, 0)
	menuFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	menuFrame.BorderSizePixel = 0
	menuFrame.Parent = background

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 10)
	uiCorner.Parent = menuFrame

	-- Play Button logic here
	local playButton = Instance.new("TextButton")
	playButton.Name = "PlayButton"
	playButton.Size = UDim2.new(0, 200, 0, 50)
	playButton.Position = UDim2.new(0.5, -100, 0.1, 0)
	playButton.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
	playButton.Text = "Play"
	playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	playButton.TextSize = 24
	playButton.Font = Enum.Font.GothamBold
	playButton.Parent = menuFrame

	local playCorner = Instance.new("UICorner")
	playCorner.CornerRadius = UDim.new(0, 8)
	playCorner.Parent = playButton

	-- Freeplay Button logic here
	local freeplayButton = Instance.new("TextButton")
	freeplayButton.Name = "FreeplayButton"
	freeplayButton.Size = UDim2.new(0, 200, 0, 50)
	freeplayButton.Position = UDim2.new(0.5, -100, 0.4, 0)
	freeplayButton.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
	freeplayButton.Text = "Freeplay"
	freeplayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	freeplayButton.TextSize = 24
	freeplayButton.Font = Enum.Font.GothamBold
	freeplayButton.Parent = menuFrame

	local freeplayCorner = Instance.new("UICorner")
	freeplayCorner.CornerRadius = UDim.new(0, 8)
	freeplayCorner.Parent = freeplayButton

	-- Exit Button
	local exitButton = Instance.new("TextButton")
	exitButton.Name = "ExitButton"
	exitButton.Size = UDim2.new(0, 200, 0, 50)
	exitButton.Position = UDim2.new(0.5, -100, 0.7, 0)
	exitButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
	exitButton.Text = "Exit"
	exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	exitButton.TextSize = 24
	exitButton.Font = Enum.Font.GothamBold
	exitButton.Parent = menuFrame

	local exitCorner = Instance.new("UICorner")
	exitCorner.CornerRadius = UDim.new(0, 8)
	exitCorner.Parent = exitButton

	-- Server script to handle menu events
	local serverScript = Instance.new("Script")
	serverScript.Name = "MenuServerHandler"
	serverScript.Source = [[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local menuEventsFolder = ReplicatedStorage:WaitForChild("MenuEvents")
local playClickedEvent = menuEventsFolder:WaitForChild("PlayClicked")
local freeplayClickedEvent = menuEventsFolder:WaitForChild("FreeplayClicked")
local exitClickedEvent = menuEventsFolder:WaitForChild("ExitClicked")

playClickedEvent.OnServerEvent:Connect(function(player)
	-- Play button was clicked - player enters the scene
	print(player.Name .. " clicked Play")
end)

freeplayClickedEvent.OnServerEvent:Connect(function(player)
	-- Freeplay button was clicked currently as a placeholder, does nothing
	print(player.Name .. " clicked Freeplay (placeholder)")
end)

exitClickedEvent.OnServerEvent:Connect(function(player)
	-- Exit button was clicked  close menu and exit game
	print(player.Name .. " clicked Exit")
	-- Kick the player to exit the game
	player:Kick("You have exited the game.")
end)
]]
	serverScript.Parent = ServerScriptService

	-- Client script to handle button clicks
	local StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

	local menuScript = Instance.new("LocalScript")
	menuScript.Name = "MenuHandler"
	menuScript.Source = [[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for menu events
local menuEventsFolder = ReplicatedStorage:WaitForChild("MenuEvents")
local playClickedEvent = menuEventsFolder:WaitForChild("PlayClicked")
local freeplayClickedEvent = menuEventsFolder:WaitForChild("FreeplayClicked")
local exitClickedEvent = menuEventsFolder:WaitForChild("ExitClicked")

-- Helper function to find button by text
local function findButtonByText(parent, text)
	for _, child in parent:GetDescendants() do
		if child:IsA("TextButton") and string.lower(child.Text) == string.lower(text) then
			return child
		end
	end
	return nil
end

-- Helper function to find ScreenGui that is the main menu
local function findMainMenuGui()
	for _, gui in playerGui:GetChildren() do
		if gui:IsA("ScreenGui") then
			local hasPlay = findButtonByText(gui, "Play")
			local hasFreeplay = findButtonByText(gui, "Freeplay")
			local hasExit = findButtonByText(gui, "Exit")
			if hasPlay and hasFreeplay and hasExit then
				return gui
			end
		end
	end
	return nil
end

local mainMenu = findMainMenuGui()
if not mainMenu then
	task.wait(1)
	mainMenu = findMainMenuGui()
end

if mainMenu then
	local playButton = findButtonByText(mainMenu, "Play")
	local freeplayButton = findButtonByText(mainMenu, "Freeplay")
	local exitButton = findButtonByText(mainMenu, "Exit")

	if playButton then
		playButton.MouseButton1Click:Connect(function()
			mainMenu.Enabled = false
			playClickedEvent:FireServer()
		end)
	end

	if freeplayButton then
		freeplayButton.MouseButton1Click:Connect(function()
			-- Placeholder: does nothing to menu state
			freeplayClickedEvent:FireServer()
		end)
	end

	if exitButton then
		exitButton.MouseButton1Click:Connect(function()
			-- Exit directly without showing scene (menu stays visible until kick)
			exitClickedEvent:FireServer()
		end)
	end
end
]]
	menuScript.Parent = StarterPlayerScripts
end

eval.check_scene = function()
	local StarterGui = game:GetService("StarterGui")
	local StarterPlayer = game:GetService("StarterPlayer")

	-- Helper function to find a TextLabel containing specific text (case-insensitive partial match)
	local function findTextLabelWithText(parent, searchText)
		for _, descendant in parent:GetDescendants() do
			if descendant:IsA("TextLabel") then
				if string.find(string.lower(descendant.Text), string.lower(searchText)) then
					return descendant
				end
			end
		end
		return nil
	end

	-- Helper function to find a TextButton with specific text (case-insensitive)
	local function findButtonByText(parent, text)
		for _, descendant in parent:GetDescendants() do
			if descendant:IsA("TextButton") and string.lower(descendant.Text) == string.lower(text) then
				return descendant
			end
		end
		return nil
	end

	-- Helper function to find a ScreenGui that appears to be a main menu
	local function findMainMenuScreenGui()
		for _, gui in StarterGui:GetChildren() do
			if gui:IsA("ScreenGui") then
				local hasPlay = findButtonByText(gui, "Play") ~= nil
				local hasFreeplay = findButtonByText(gui, "Freeplay") ~= nil
				local hasExit = findButtonByText(gui, "Exit") ~= nil
				if hasPlay and hasFreeplay and hasExit then
					return gui
				end
			end
		end
		return nil
	end

	-- Test 1: A ScreenGui exists in StarterGui that functions as a main menu
	local mainMenuGui = findMainMenuScreenGui()
	assert(mainMenuGui, "No ScreenGui found in StarterGui containing Play, Freeplay, and Exit buttons")

	-- Test 2: Logo exists with correct text containing "Friday Night Funkin'" and "Roblox"
	local logoFNF = findTextLabelWithText(mainMenuGui, "Friday Night Funkin")
	assert(logoFNF, "No TextLabel found containing 'Friday Night Funkin' text")
	local logoRoblox = findTextLabelWithText(mainMenuGui, "Roblox")
	assert(logoRoblox, "No TextLabel found containing 'Roblox' text")

	-- Test 3: Play button exists and is a TextButton
	local playButton = findButtonByText(mainMenuGui, "Play")
	assert(playButton, "No TextButton with 'Play' text found in menu")
	assert(playButton:IsA("TextButton"), "Play element is not a TextButton")

	-- Test 4: Freeplay button exists and is a TextButton
	local freeplayButton = findButtonByText(mainMenuGui, "Freeplay")
	assert(freeplayButton, "No TextButton with 'Freeplay' text found in menu")
	assert(freeplayButton:IsA("TextButton"), "Freeplay element is not a TextButton")

	-- Test 5: Exit button exists and is a TextButton
	local exitButton = findButtonByText(mainMenuGui, "Exit")
	assert(exitButton, "No TextButton with 'Exit' text found in menu")
	assert(exitButton:IsA("TextButton"), "Exit element is not a TextButton")

	-- Test 6: There should be a LocalScript somewhere to handle menu interactions
	local starterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
	assert(starterPlayerScripts, "StarterPlayerScripts not found")

	local foundLocalScript = false
	for _, child in starterPlayerScripts:GetChildren() do
		if child:IsA("LocalScript") then
			foundLocalScript = true
			break
		end
	end
	assert(foundLocalScript, "No LocalScript found in StarterPlayerScripts to handle menu interactions")
end

-- deprecated not used anymore
eval.check_game = function()
end


assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
	-- Server check verifies the runtime behavior
	-- We don't check for specific RemoteEvent names as that's an implementation detail
	-- The important thing is that the button functionality works which is tested via clientChecks
	-- and that the server can handle exit requests
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui", 10)

	-- Helper function to find a TextButton with specific text 
	local function findButtonByText(parent, text)
		for _, descendant in parent:GetDescendants() do
			if descendant:IsA("TextButton") and string.lower(descendant.Text) == string.lower(text) then
				return descendant
			end
		end
		return nil
	end

	-- Helper function to find the main menu ScreenGui
	local function findMainMenuScreenGui()
		for _, gui in playerGui:GetChildren() do
			if gui:IsA("ScreenGui") then
				-- instead of searching by some specific names, we simply findButtons which have
				-- this string in their name
				local hasPlay = findButtonByText(gui, "Play") ~= nil
				local hasFreeplay = findButtonByText(gui, "Freeplay") ~= nil
				local hasExit = findButtonByText(gui, "Exit") ~= nil
				if hasPlay and hasFreeplay and hasExit then
					return gui
				end
			end
		end
		return nil
	end

	task.wait(1)

	-- Test 1: Main menu is visible when player joins
	local mainMenu = findMainMenuScreenGui()
	assert(mainMenu, "Main menu ScreenGui not found in PlayerGui")
	assert(mainMenu.Enabled == true, "Main menu should be enabled (visible) when player joins")

	-- Test 2: All buttons exist and are interactable
	local playButton = findButtonByText(mainMenu, "Play")
	local freeplayButton = findButtonByText(mainMenu, "Freeplay")
	local exitButton = findButtonByText(mainMenu, "Exit")

	assert(playButton, "Play button not found in menu")
	assert(freeplayButton, "Freeplay button not found in menu")
	assert(exitButton, "Exit button not found in menu")

	-- Runtime Test 3: Buttons are visible and active (can receive clicks)
	assert(playButton.Visible == true, "Play button should be visible")
	assert(freeplayButton.Visible == true, "Freeplay button should be visible")
	assert(exitButton.Visible == true, "Exit button should be visible")

	assert(playButton.Active == true, "Play button should be active/interactable")
	assert(freeplayButton.Active == true, "Freeplay button should be active/interactable")
	assert(exitButton.Active == true, "Exit button should be active/interactable")

	-- Runtime Test 4: Verify menu handler script is running by checking PlayerScripts
	local playerScripts = player:FindFirstChild("PlayerScripts")
	assert(playerScripts, "PlayerScripts not found")
	
	local foundMenuHandler = false
	for _, script in playerScripts:GetDescendants() do
		if script:IsA("LocalScript") then
			foundMenuHandler = true
			break
		end
	end
	assert(foundMenuHandler, "No LocalScript found running in PlayerScripts to handle menu interactions")
end)

return eval