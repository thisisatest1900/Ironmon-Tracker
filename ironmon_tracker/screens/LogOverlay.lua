LogOverlay = {
	Labels = {
		header = "Log Viewer",
		bstStatBox = "Base Stats",
		bstTotalFormat = "Total: %s", -- e.g. Total: 505
		gymTMs = "Gym TMs",
		otherTMs = "Other TMs",
		tabFormat = "%s",
		pageFormat = "Page %s/%s", -- e.g. Page 1/3
		partyPokemonLevelFormat = "Lv.%s", -- e.g. Lv.23
		filterBy = "Filter by:",
		showMoreEvos = "See more",
		shareSeed = "Copy/paste everything below to share. Load it through Randomizer --> Premade Seed.",
	},
	Tabs = {
		POKEMON = Constants.Words.POKEMON,
		POKEMON_ZOOM = Constants.Words.POKEMON .. " Zoom",
		POKEMON_ZOOM_LEVELMOVES = "Levelup Moves", -- non-primary tab
		POKEMON_ZOOM_TMMOVES = "TM Moves", -- non-primary tab
		TRAINER = "Trainers",
		TRAINER_ZOOM = "Trainer Zoom",
		TMS = "TMs",
		MISC = "Misc.",
		GO_BACK = "Back",
	},
	debugTrainerIconBoxes = false,
	margin = 2,
	tabHeight = 12,
	currentTab = nil,
	currentTabInfoId = nil,
	isDisplayed = false,
	currentPreEvoSet = 1,
	currentEvoSet = 1, -- Ideally move this somewhere else
	prevEvosPerSet = 1,
	evosPerSet = 3, -- Ideally move this somewhere else
	preEvoSetting = "Show Pre Evolutions",
	isGameOver = false, -- Set to true when game is over, so we known to show game over screen if X is pressed
}

LogOverlay.Windower = {
	currentPage = nil,
	totalPages = nil,
	filterGrid = "#",
	getPageText = function(self)
		if self.totalPages == nil or self.totalPages < 1 then return "Page" end
		return string.format(LogOverlay.Labels.pageFormat, self.currentPage, self.totalPages)
	end,
	prevPage = function(self)
		if self.totalPages == nil or self.totalPages <= 1 then return end
		self.currentPage = ((self.currentPage - 2 + self.totalPages) % self.totalPages) + 1
	end,
	nextPage = function(self)
		if self.totalPages == nil or self.totalPages <= 1 then return end
		self.currentPage = (self.currentPage % self.totalPages) + 1
	end,
	changeTab = function(self, newTab, pageNum, totalPages, tabInfoId)
		local prevTab = {
			tab = LogOverlay.currentTab,
			infoId = LogOverlay.currentTabInfoId,
			page = self.currentPage,
			totalPages = self.totalPages,
		}

		LogOverlay.currentTab = newTab
		LogOverlay.currentTabInfoId = tabInfoId or LogOverlay.currentTabInfoId
		self.currentPage = pageNum or self.currentPage or 1
		self.totalPages = totalPages or self.totalPages or 1

		if newTab == LogOverlay.Tabs.POKEMON or newTab == LogOverlay.Tabs.TRAINER or newTab == LogOverlay.Tabs.MISC then
			LogOverlay.TabHistory = {}
		elseif newTab == LogOverlay.Tabs.TMS then
			LogOverlay.TabHistory = {}
		elseif newTab == LogOverlay.Tabs.POKEMON_ZOOM then
			LogOverlay.currentEvoSet = 1
			LogOverlay.currentTabData = DataHelper.buildPokemonLogDisplay(tabInfoId)
			LogOverlay.buildPokemonZoomButtons(LogOverlay.currentTabData)
			if prevTab.tab ~= LogOverlay.Tabs.POKEMON_ZOOM then
				table.insert(LogOverlay.TabHistory, prevTab)
			end
		elseif newTab == LogOverlay.Tabs.TRAINER_ZOOM then
			LogOverlay.currentTabData = DataHelper.buildTrainerLogDisplay(tabInfoId)
			LogOverlay.buildTrainerZoomButtons(LogOverlay.currentTabData)
			if prevTab.tab ~= LogOverlay.Tabs.TRAINER_ZOOM then
				table.insert(LogOverlay.TabHistory, prevTab)
			end
		elseif newTab == LogOverlay.Tabs.GO_BACK then
			prevTab = table.remove(LogOverlay.TabHistory)
			if prevTab ~= nil then
				self:changeTab(prevTab.tab, prevTab.page, prevTab.totalPages, prevTab.infoId)
			else
				LogOverlay.realignPokemonGrid()
				self:changeTab(LogOverlay.Tabs.POKEMON)
			end
			return
		else -- Currently unused
			table.insert(LogOverlay.TabHistory, prevTab)
		end
		LogOverlay.refreshTabBar()
		LogOverlay.refreshInnerButtons()
	end,
}

LogOverlay.PokemonMovesPagination = {
	currentPage = 0,
	currentTab = 0,
	totalPages = 0,
	movesPerPage = 8,
	totalLearnedMoves = 0, -- set each time new pokemon zoom is built
	totalTMMoves = 0, -- set each time new pokemon zoom is built
	prevPage = function(self)
		if self.totalPages <= 1 then return end
		self.currentPage = ((self.currentPage - 2 + self.totalPages) % self.totalPages) + 1
	end,
	nextPage = function(self)
		if self.totalPages <= 1 then return end
		self.currentPage = (self.currentPage % self.totalPages) + 1
	end,
	changeTab = function(self, newTab)
		self.currentTab = newTab
		self.currentPage = 1

		if newTab == LogOverlay.Tabs.POKEMON_ZOOM_LEVELMOVES then
			self.totalPages = math.ceil(self.totalLearnedMoves / self.movesPerPage)
		elseif newTab == LogOverlay.Tabs.POKEMON_ZOOM_TMMOVES then
			self.totalPages = math.ceil(self.totalTMMoves / self.movesPerPage)
		else -- Currently unused
			self.totalPages = 1
		end
		LogOverlay.refreshInnerButtons()
	end,
}

LogOverlay.TabBarButtons = {
	PokemonTab = {
		type = Constants.ButtonTypes.NO_BORDER,
		text = LogOverlay.Tabs.POKEMON,
		textColor = "Header text",
		tab = LogOverlay.Tabs.POKEMON,
		box = { LogOverlay.margin + 1, 0, 41, 11, },
		updateText = function(self)
			if LogOverlay.currentTab == self.tab then
				self.text = string.format(LogOverlay.Labels.tabFormat, self.tab)
				self.textColor = Theme.headerHighlightKey
			else
				self.text = self.tab
				self.textColor = "Header text"
			end
		end,
		draw = function(self)
			-- Draw an underline if selected
			if self.textColor == Theme.headerHighlightKey then
				local x1, x2 = self.box[1] + 2, self.box[1] + self.box[3] - 1
				local y1, y2 = self.box[2] + self.box[4] - 1, self.box[2] + self.box[4] - 1
				gui.drawLine(x1, y1, x2, y2, Theme.COLORS[self.textColor])
			end
		end,
		onClick = function(self)
			if LogOverlay.currentTab ~= self.tab then
				LogOverlay.realignPokemonGrid()
				LogOverlay.Windower:changeTab(self.tab)
				Program.redraw(true)
			end
		end,
	},
	TrainersTab = {
		type = Constants.ButtonTypes.NO_BORDER,
		text = LogOverlay.Tabs.TRAINER,
		textColor = "Header text",
		tab = LogOverlay.Tabs.TRAINER,
		box = { LogOverlay.margin + 45, 0, 34, 11, },
		updateText = function(self)
			if LogOverlay.currentTab == self.tab then
				self.text = string.format(LogOverlay.Labels.tabFormat, self.tab)
				self.textColor = Theme.headerHighlightKey
			else
				self.text = self.tab
				self.textColor = "Header text"
			end
		end,
		draw = function(self)
			-- Draw an underline if selected
			if self.textColor == Theme.headerHighlightKey then
				local x1, x2 = self.box[1] + 2, self.box[1] + self.box[3] - 1
				local y1, y2 = self.box[2] + self.box[4] - 1, self.box[2] + self.box[4] - 1
				gui.drawLine(x1, y1, x2, y2, Theme.COLORS[self.textColor])
			end
		end,
		onClick = function(self)
			if LogOverlay.currentTab ~= self.tab then
				LogOverlay.realignTrainerGrid()
				LogOverlay.Windower:changeTab(self.tab)
				Program.redraw(true)
			end
		end,
	},
	TMsTab = {
		type = Constants.ButtonTypes.NO_BORDER,
		text = LogOverlay.Tabs.TMS,
		textColor = "Header text",
		tab = LogOverlay.Tabs.TMS,
		box = { LogOverlay.margin + 45 + 38, 0, 18, 11, },
		updateText = function(self)
			if LogOverlay.currentTab == self.tab then
				self.text = string.format(LogOverlay.Labels.tabFormat, self.tab)
				self.textColor = Theme.headerHighlightKey
			else
				self.text = self.tab
				self.textColor = "Header text"
			end
		end,
		draw = function(self)
			-- Draw an underline if selected
			if self.textColor == Theme.headerHighlightKey then
				local x1, x2 = self.box[1] + 2, self.box[1] + self.box[3] - 1
				local y1, y2 = self.box[2] + self.box[4] - 1, self.box[2] + self.box[4] - 1
				gui.drawLine(x1, y1, x2, y2, Theme.COLORS[self.textColor])
			end
		end,
		onClick = function(self)
			if LogOverlay.currentTab ~= self.tab then
				LogOverlay.realignTMGrid()
				LogOverlay.Windower:changeTab(self.tab)
				Program.redraw(true)
			end
		end,
	},
	MiscTab = {
		type = Constants.ButtonTypes.NO_BORDER,
		text = LogOverlay.Tabs.MISC,
		textColor = "Header text",
		tab = LogOverlay.Tabs.MISC,
		box = { LogOverlay.margin + 45 + 38 + 22, 0, 22, 11, },
		updateText = function(self)
			if LogOverlay.currentTab == self.tab then
				self.text = string.format(LogOverlay.Labels.tabFormat, self.tab)
				self.textColor = Theme.headerHighlightKey
			else
				self.text = self.tab
				self.textColor = "Header text"
			end
		end,
		draw = function(self)
			-- Draw an underline if selected
			if self.textColor == Theme.headerHighlightKey then
				local x1, x2 = self.box[1] + 2, self.box[1] + self.box[3] - 1
				local y1, y2 = self.box[2] + self.box[4] - 1, self.box[2] + self.box[4] - 1
				gui.drawLine(x1, y1, x2, y2, Theme.COLORS[self.textColor])
			end
		end,
		onClick = function(self)
			if LogOverlay.currentTab ~= self.tab then
				LogOverlay.Windower:changeTab(self.tab, 1, 1)
				Program.redraw(true)
			end
		end,
	},
	XIcon = {
		type = Constants.ButtonTypes.PIXELIMAGE,
		image = Constants.PixelImages.CLOSE,
		textColor = Theme.headerHighlightKey,
		box = { LogOverlay.margin + 228, 2, 10, 10 },
		updateText = function(self)
			self.textColor = Theme.headerHighlightKey
			if LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM or LogOverlay.currentTab == LogOverlay.Tabs.TRAINER_ZOOM then
				self.image = Constants.PixelImages.LEFT_ARROW
				self.box[2] = 1
			else
				self.image = Constants.PixelImages.CLOSE
				self.box[2] = 2
			end
		end,
		onClick = function(self)
			if self.image == Constants.PixelImages.CLOSE then
				LogOverlay.TabHistory = {}
				LogOverlay.isDisplayed = false
				if LogOverlay.isGameOver then
					Program.changeScreenView(GameOverScreen)
				elseif not Program.isValidMapLocation() then
					-- If the game hasn't started yet
					Program.changeScreenView(StartupScreen)
				else
					Program.changeScreenView(TrackerScreen)
				end
			else -- Constants.PixelImages.PREVIOUS_BUTTON
				LogOverlay.Windower:changeTab(LogOverlay.Tabs.GO_BACK)
				Program.redraw(true)
			end
		end,
	},
}

LogOverlay.Buttons = {
	CurrentPage = {
		type = Constants.ButtonTypes.NO_BORDER,
		text = "", -- Set later via updateText()
		textColor = Theme.headerHighlightKey,
		box = { LogOverlay.margin + 151, 0, 50, 10, },
		isVisible = function() return LogOverlay.Windower.totalPages > 1 end, -- Likely won't use, unsure where to place it
		updateText = function(self)
			self.text = LogOverlay.Windower:getPageText() or ""
			if LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM or LogOverlay.currentTab == LogOverlay.Tabs.TRAINER_ZOOM then
				self.textColor = Theme.headerHighlightKey --"Lower box text"
			else
				self.textColor = Theme.headerHighlightKey -- "Default text"
			end
		end,
	},
	PrevPage = {
		type = Constants.ButtonTypes.PIXELIMAGE,
		image = Constants.PixelImages.LEFT_ARROW,
		textColor = "Default text",
		box = { LogOverlay.margin + 4, LogOverlay.tabHeight + 65, 10, 10, },
		isVisible = function() return LogOverlay.Windower.totalPages > 1 end,
		updateText = function(self)
			if LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM or LogOverlay.currentTab == LogOverlay.Tabs.TRAINER_ZOOM then
				self.textColor = "Lower box text"
			else
				self.textColor = "Default text"
			end
		end,
		onClick = function(self)
			LogOverlay.Windower:prevPage()
			LogOverlay.Buttons.CurrentPage:updateText()
			Program.redraw(true)
		end,
	},
	NextPage = {
		type = Constants.ButtonTypes.PIXELIMAGE,
		image = Constants.PixelImages.RIGHT_ARROW,
		textColor = "Default text",
		box = { Constants.SCREEN.WIDTH - LogOverlay.margin - 13, LogOverlay.tabHeight + 65, 10, 10, },
		isVisible = function() return LogOverlay.Windower.totalPages > 1 end,
		updateText = function(self)
			if LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM or LogOverlay.currentTab == LogOverlay.Tabs.TRAINER_ZOOM then
				self.textColor = "Lower box text"
			else
				self.textColor = "Default text"
			end
		end,
		onClick = function(self)
			LogOverlay.Windower:nextPage()
			LogOverlay.Buttons.CurrentPage:updateText()
			Program.redraw(true)
		end,
	},
	ShareRandomizer = {
		type = Constants.ButtonTypes.FULL_BORDER,
		text = "Share Seed",
		textColor = "Default text",
		tab = LogOverlay.Tabs.MISC,
		box = { Constants.SCREEN.WIDTH - LogOverlay.margin - 55, LogOverlay.tabHeight + 16, 50, 11 },
		boxColors = { "Upper box border", "Upper box background" },
		isVisible = function(self) return LogOverlay.currentTab == self.tab end,
		onClick = function(self) LogOverlay.openRandomizerShareWindow() end,
	},
	PreEvoSettingButton = {
		type = Constants.ButtonTypes.CHECKBOX,
		text =  LogOverlay.preEvoSetting,
		textColor = "Default text",
		boxColors = { "Upper box border", "Upper box background" },
		tab = LogOverlay.Tabs.MISC,
		box = { LogOverlay.margin + 4, 110, Constants.Font.SIZE - 1, Constants.Font.SIZE - 1, },
		clickableArea = { LogOverlay.margin + 4, 110, Utils.calcWordPixelLength(LogOverlay.preEvoSetting) + 10, Constants.Font.SIZE, },
		isVisible = function(self) return LogOverlay.currentTab == self.tab end,
		toggleState = false,
		toggleColor = "Positive text",
		onClick = function(self)
			self.toggleState = not self.toggleState
			Options.updateSetting("Show Pre Evolutions", self.toggleState)
			Main.SaveSettings()
		end,
	},
}

-- Holds temporary buttons that only exist while drilling down on specific log info, e.g. pokemon evo icons
LogOverlay.TemporaryButtons = {}

-- Holds all of the parsed data in nicely formatted buttons for display and interaction
LogOverlay.PagedButtons = {}

-- A stack manage the back-button within tabs, each element is { tab, page, }
LogOverlay.TabHistory = {}

-- Navigation filters for each of the window tabs. Each has a label for the button, and a sort function for the grid
LogOverlay.NavFilters = {
	Trainers = {
		{
			label = TrainerData.TrainerGroups.All,
			sortFunc = function(a, b)
				if a.group < b.group then
					return true
				elseif a.group == b.group then
					if a.group == TrainerData.TrainerGroups.Rival or a.group == TrainerData.TrainerGroups.Boss then -- special sort for rival/wally #s
						return a.text < b.text
					elseif a.filename < b.filename then
						return a.filename < b.filename
					end
				end
				return false
			end,
		},
		{
			label = TrainerData.TrainerGroups.Rival,
			sortFunc = function(a, b) return a.text < b.text end,
		},
		{
			label = TrainerData.TrainerGroups.Gym,
			sortFunc = function(a, b) return a.filename:sub(-1) < b.filename:sub(-1) end,
		},
		{
			label = TrainerData.TrainerGroups.Elite4,
			sortFunc = function(a, b) return a.filename:sub(-1) < b.filename:sub(-1) end,
		},
		{
			label = TrainerData.TrainerGroups.Boss,
			sortFunc = function(a, b) return a.text < b.text end,
		},
		-- { -- Temp Removing both of these until better data gets sorted out
		-- 	label = TrainerData.TrainerGroups.Other,
		-- 	sortFunc = function(a, b) return a.text < b.text end,
		-- },
		-- {
		-- 	label = "(?)",
		-- },
	},
	TMs = {
		{ -- If this changes from index 2, update it's references
			label = "TM #",
			sortFunc = function(a, b) return a.tmNumber < b.tmNumber end,
		},
		{ -- If this changes from index 2, update it's references
			label = "Gym TMs",
			sortFunc = function(a, b) return a.gymNumber < b.gymNumber end,
		},
	},
}

function LogOverlay.initialize()
	LogOverlay.currentTab = nil
	LogOverlay.isDisplayed = false
	LogOverlay.isGameOver = false
	LogOverlay.currentTab = nil

	LogOverlay.TabHistory = {}

	LogOverlay.Buttons.PreEvoSettingButton.toggleState = Options[LogOverlay.preEvoSetting]

	for _, button in pairs(LogOverlay.TabBarButtons) do
		if button.textColor == nil then
			button.textColor = "Header text"
		end
		if button.boxColors == nil then
			button.boxColors = { "Upper box border", "Main background" }
		end
	end
	for _, button in pairs(LogOverlay.Buttons) do
		if button.textColor == nil then
			button.textColor = "Default text"
		end
		if button.boxColors == nil then
			button.boxColors = { "Upper box border", "Upper box background" }
		end
	end

	LogOverlay.Buttons.CurrentPage:updateText()
	LogOverlay.Buttons.PreEvoSettingButton.toggleState = Options["Show Pre Evolutions"]
end

-- Builds out paged-buttons that are shown on the log viewer overlay based on the parse data
function LogOverlay.buildPagedButtons()
	LogOverlay.PagedButtons = {}

	local navStartX, navStartY = 4, LogOverlay.tabHeight + 1 -- Alternative, at the bottom: Constants.SCREEN.HEIGHT - LogOverlay.margin - 13

	-- Build Pokemon buttons
	LogOverlay.PagedButtons.Pokemon = {}
	for id = 1, PokemonData.totalPokemon, 1 do
		if RandomizerLog.Data.Pokemon[id] ~= nil then
			local button = {
				type = Constants.ButtonTypes.POKEMON_ICON,
				pokemonID = id,
				pokemonName = PokemonData.Pokemon[id].name,
				tab = LogOverlay.Tabs.POKEMON,
				isVisible = function(self)
					return LogOverlay.currentTab == self.tab and LogOverlay.Windower.currentPage == self.pageVisible
				end,
				includeInGrid = function(self)
					return LogOverlay.Windower.filterGrid == "#" or LogOverlay.Windower.filterGrid == self.pokemonName:sub(1,1)
				end,
				getIconPath = function(self)
					local iconset = Options.IconSetMap[Options["Pokemon icon set"]]
					return FileManager.buildImagePath(iconset.folder, tostring(self.pokemonID), iconset.extension)
				end,
				onClick = function(self)
					LogOverlay.Windower:changeTab(LogOverlay.Tabs.POKEMON_ZOOM, 1, 1, self.pokemonID)
					InfoScreen.changeScreenView(InfoScreen.Screens.POKEMON_INFO, self.pokemonID) -- implied redraw
				end,
			}
			table.insert(LogOverlay.PagedButtons.Pokemon, button)
		end
	end

	-- Build Pokemon navigation
	local navOffsetX = navStartX
	local navLabels = { "#", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "(?)", }
	for _, navLabel in ipairs(navLabels) do
		local labelWidth = Utils.calcWordPixelLength(navLabel) + 2 -- +2 to make it a bit wider
		local jumpBtn = {
			type = Constants.ButtonTypes.NO_BORDER,
			text = navLabel,
			textColor = "Default text",
			tab = LogOverlay.Tabs.POKEMON,
			box = { LogOverlay.margin + navOffsetX, navStartY, labelWidth, 11 },
			isVisible = function(self) return LogOverlay.currentTab == self.tab end,
			updateText = function(self)
				if LogOverlay.Windower.filterGrid == self.text then
					self.textColor = "Intermediate text"
				else
					self.textColor = "Default text"
				end
			end,
			draw = function(self)
				-- Draw an underline if selected
				if self.textColor == "Intermediate text" then
					local x1, x2 = self.box[1] + 2, self.box[1] + self.box[3] + 1
					local y1, y2 = self.box[2] + self.box[4] - 1, self.box[2] + self.box[4] - 1
					gui.drawLine(x1, y1, x2, y2, Theme.COLORS[self.textColor])
				end
			end,
			onClick = function(self)
				if self.text == "(?)" then
					local pokemonId = Utils.randomPokemonID()
					LogOverlay.Windower:changeTab(LogOverlay.Tabs.POKEMON_ZOOM, 1, 1, pokemonId)
					InfoScreen.changeScreenView(InfoScreen.Screens.POKEMON_INFO, pokemonId) -- implied redraw
					return
				end

				local sortFunc
				if self.text == "#" then
					sortFunc = function(a, b) return a.pokemonID < b.pokemonID end
				else
					sortFunc = function(a, b) return a.pokemonName < b.pokemonName end
				end
				LogOverlay.realignPokemonGrid(self.text, sortFunc)
				LogOverlay.refreshInnerButtons()
				Program.redraw(true)
			end,
		}
		table.insert(LogOverlay.Buttons, jumpBtn)
		navOffsetX = navOffsetX + labelWidth + 1
		if navLabel == "#" then
			navOffsetX = navOffsetX + 8
		elseif navLabel == "Z" then
			navOffsetX = navOffsetX + 8
		end
	end

	-- Determine gym TMs for the game, they'll be highlighted
	local gymTMs = {}
	for i, gymTM in ipairs(TrainerData.GymTMs) do
		gymTMs[gymTM.number] = {
			leader = gymTM.leader,
			gymNumber = i,
			trainerId = nil, -- this gets added in later
		}
	end

	-- Build Trainer buttons
	LogOverlay.PagedButtons.Trainers = {}
	for id, trainerData in pairs(RandomizerLog.Data.Trainers) do
		local trainerInfo = TrainerData.getTrainerInfo(id)
		-- TODO: Implement actual name laters when full trainer list is ready
		-- local customName = Utils.inlineIf(trainerInfo.name ~= "Unknown", trainerInfo.name, trainerData.name)
		local customName = trainerInfo.name
		local fileInfo = TrainerData.FileInfo[trainerInfo.filename] or { width = 40, height = 40 }
		local button = {
			type = Constants.ButtonTypes.IMAGE,
			image = FileManager.buildImagePath(FileManager.Folders.Trainers, trainerInfo.filename, FileManager.Extensions.TRAINER),
			text = customName,
			trainerId = id,
			filename = trainerInfo.filename, -- helpful for sorting later
			dimensions = { width = fileInfo.width, height = fileInfo.height, extraX = fileInfo.offsetX, extraY = fileInfo.offsetY, },
			group = trainerInfo.group,
			tab = LogOverlay.Tabs.TRAINER,
			isVisible = function(self) return LogOverlay.currentTab == self.tab and LogOverlay.Windower.currentPage == self.pageVisible end,
			includeInGrid = function(self)
				local shouldInclude = LogOverlay.Windower.filterGrid == TrainerData.TrainerGroups.All or LogOverlay.Windower.filterGrid == self.group
				local shouldExclude = trainerInfo.name == "Unknown"
				-- Exclude extra rivals
				if trainerInfo.whichRival ~= nil and Tracker.Data.whichRival ~= nil and Tracker.Data.whichRival ~= trainerInfo.whichRival then
					shouldExclude = true
				end
				return shouldInclude and not shouldExclude
			end,
			onClick = function(self)
				LogOverlay.Windower:changeTab(LogOverlay.Tabs.TRAINER_ZOOM, 1, 1, self.trainerId)
				Program.redraw(true)
				-- InfoScreen.changeScreenView(InfoScreen.Screens.TRAINER_INFO, self.trainerId) -- TODO: (future feature) implied redraw
			end,
		}

		if trainerInfo ~= nil and trainerInfo.group == TrainerData.TrainerGroups.Gym then
			local gymNumber = tonumber(trainerInfo.filename:sub(-1)) -- e.g. "frlg-gymleader-1"
			if gymNumber ~= nil then
				-- Find the gym leader's TM and add it's trainer id to that tm info
				for _, gymTMInfo in pairs(gymTMs) do
					if gymTMInfo.gymNumber == gymNumber then
						gymTMInfo.trainerId = id
						break
					end
				end
			end
		end

		table.insert(LogOverlay.PagedButtons.Trainers, button)
	end

	-- Build Trainer navigation
	navOffsetX = navStartX + 40
	for _, navLabel in ipairs(LogOverlay.NavFilters.Trainers) do
		local labelWidth = Utils.calcWordPixelLength(navLabel.label) + 4
		local jumpBtn = {
			type = Constants.ButtonTypes.NO_BORDER,
			text = navLabel.label,
			textColor = "Default text",
			tab = LogOverlay.Tabs.TRAINER,
			box = { LogOverlay.margin + navOffsetX, navStartY, labelWidth, 11 },
			isVisible = function(self) return LogOverlay.currentTab == self.tab end,
			updateText = function(self)
				if LogOverlay.Windower.filterGrid == self.text then
					self.textColor = "Intermediate text"
				else
					self.textColor = "Default text"
				end
			end,
			draw = function(self)
				-- Draw an underline if selected
				if self.textColor == "Intermediate text" then
					local x1, x2 = self.box[1] + 2, self.box[1] + self.box[3] - 1
					local y1, y2 = self.box[2] + self.box[4] - 1, self.box[2] + self.box[4] - 1
					gui.drawLine(x1, y1, x2, y2, Theme.COLORS[self.textColor])
				end
			end,
			onClick = function(self)
				if self.text == "(?)" then
					local trainerId = Utils.randomTrainerID()
					LogOverlay.Windower:changeTab(LogOverlay.Tabs.TRAINER_ZOOM, 1, 1, trainerId)
					Program.redraw(true)
					-- InfoScreen.changeScreenView(InfoScreen.Screens.TRAINER_INFO, self.trainerId) -- TODO: (future feature) implied redraw
					return
				end
				LogOverlay.realignTrainerGrid(self.text, navLabel.sortFunc)
				LogOverlay.refreshInnerButtons()
				Program.redraw(true)
			end,
		}
		table.insert(LogOverlay.Buttons, jumpBtn)
		navOffsetX = navOffsetX + labelWidth + 6
	end

	LogOverlay.PagedButtons.TMs = {}
	for tmNumber, tm in pairs(RandomizerLog.Data.TMs) do
		local gymLeader, gymNumber, trainerId, filterGroup
		if gymTMs[tmNumber] ~= nil then
			gymLeader = gymTMs[tmNumber].leader
			gymNumber = gymTMs[tmNumber].gymNumber
			trainerId = gymTMs[tmNumber].trainerId
			filterGroup = "Gym TMs"
		else
			gymLeader = "None"
			gymNumber = 0
			-- if not a gym TM, then it doesn't have a trainerId or filterGroup
		end
		local moveName
		if MoveData.Moves[tm.moveId] ~= nil then
			moveName = MoveData.Moves[tm.moveId].name
		else
			moveName = tm.name
		end
		local button = {
			type = Constants.ButtonTypes.NO_BORDER,
			text = string.format("TM%02d  %s", tmNumber, moveName),
			textColor = "Default text",
			tmNumber = tmNumber,
			moveId = tm.moveId,
			gymLeader = gymLeader,
			gymNumber = gymNumber,
			trainerId = trainerId,
			group = filterGroup,
			tab = LogOverlay.Tabs.TMS,
			isVisible = function(self) return LogOverlay.currentTab == self.tab and LogOverlay.Windower.currentPage == self.pageVisible end,
			includeInGrid = function(self)
				local shouldInclude = LogOverlay.Windower.filterGrid == LogOverlay.NavFilters.TMs[1].label or LogOverlay.Windower.filterGrid == self.group
				local shouldExclude = nil
				return shouldInclude and not shouldExclude
			end,
			onClick = function(self)
				if MoveData.isValid(self.moveId) then
					InfoScreen.changeScreenView(InfoScreen.Screens.MOVE_INFO, self.moveId) -- implied redraw
				end
			end,
		}
		table.insert(LogOverlay.PagedButtons.TMs, button)
	end

	-- Build TMs navigation
	navOffsetX = navStartX + 40
	for _, navLabel in ipairs(LogOverlay.NavFilters.TMs) do
		local labelWidth = Utils.calcWordPixelLength(navLabel.label) + 2
		local filterBtn = {
			type = Constants.ButtonTypes.NO_BORDER,
			text = navLabel.label,
			textColor = "Default text",
			tab = LogOverlay.Tabs.TMS,
			box = { LogOverlay.margin + navOffsetX, navStartY, labelWidth, 11 },
			isVisible = function(self) return LogOverlay.currentTab == self.tab end,
			updateText = function(self)
				if LogOverlay.Windower.filterGrid == self.text then
					self.textColor = "Intermediate text"
				else
					self.textColor = "Default text"
				end
			end,
			draw = function(self)
				-- Draw an underline if selected
				if self.textColor == "Intermediate text" then
					local x1, x2 = self.box[1] + 2, self.box[1] + self.box[3] + 1
					local y1, y2 = self.box[2] + self.box[4] - 1, self.box[2] + self.box[4] - 1
					gui.drawLine(x1, y1, x2, y2, Theme.COLORS[self.textColor])
				end
			end,
			onClick = function(self)
				LogOverlay.realignTMGrid(self.text, navLabel.sortFunc)
				LogOverlay.refreshInnerButtons()
				Program.redraw(true)
			end,
		}
		table.insert(LogOverlay.Buttons, filterBtn)
		navOffsetX = navOffsetX + labelWidth + 9
	end
	-- Sort and build out the permanent gym buttons
	LogOverlay.buildTMGymButtons()

	-- First main page viewed by default is the Pokemon Window, so set that up now
	LogOverlay.realignPokemonGrid()
end

-- Also sets LogOverlay.Windower: { currentPage, totalPages, filterGrid }
function LogOverlay.realignPokemonGrid(gridFilter, sortFunc)
	-- Default grid to Pokédex number
	gridFilter = gridFilter or "#"
	sortFunc = sortFunc or (function(a, b) return a.pokemonID < b.pokemonID end)

	LogOverlay.Windower.filterGrid = gridFilter

	local buttonSet = LogOverlay.PagedButtons.Pokemon
	local x = LogOverlay.margin + 19
	local y = LogOverlay.tabHeight + 11
	local itemWidth = 32
	local itemHeight = 32
	local horizontalSpacer = 23
	local verticalSpacer = 1

	table.sort(buttonSet, sortFunc)
	LogOverlay.Windower.totalPages = LogOverlay.gridAlign(buttonSet, x, y, itemWidth, itemHeight, horizontalSpacer, verticalSpacer)
	LogOverlay.Windower.currentPage = 1
	LogOverlay.Buttons.CurrentPage:updateText()
end

-- Also sets LogOverlay.Windower: { currentPage, totalPages, filterGrid }
function LogOverlay.realignTrainerGrid(gridFilter, sortFunc)
	-- Default grid to Gym Leaders
	gridFilter = gridFilter or TrainerData.TrainerGroups.Gym
	sortFunc = sortFunc or (function(a, b) return a.filename:sub(-1) < b.filename:sub(-1) end)

	LogOverlay.Windower.filterGrid = gridFilter

	local buttonSet = LogOverlay.PagedButtons.Trainers
	local x = LogOverlay.margin + 17
	local y = LogOverlay.tabHeight + 11
	local itemWidth = nil -- each image has its own width
	local itemHeight = nil -- each image has its own height
	local horizontalSpacer = 10
	local verticalSpacer = 5

	table.sort(buttonSet, sortFunc)
	LogOverlay.Windower.totalPages = LogOverlay.gridAlign(buttonSet, x, y, itemWidth, itemHeight, horizontalSpacer, verticalSpacer)
	LogOverlay.Windower.currentPage = 1
	LogOverlay.Buttons.CurrentPage:updateText()
end

-- Also sets LogOverlay.Windower: { currentPage, totalPages, filterGrid }
function LogOverlay.realignTMGrid(gridFilter, sortFunc)
	-- Default grid to Gym TMs
	gridFilter = gridFilter or "Gym TMs"
	sortFunc = sortFunc or (function(a, b) return a.gymNumber < b.gymNumber end)

	LogOverlay.Windower.filterGrid = gridFilter

	local buttonSet = LogOverlay.PagedButtons.TMs
	local x = LogOverlay.margin + 25
	local y = LogOverlay.tabHeight + 14
	local itemWidth = 80
	local itemHeight = 11
	local horizontalSpacer = 17
	local verticalSpacer = 2
	if gridFilter == "Gym TMs" then
		x = x + 12
		y = y + 2
		verticalSpacer = 5
	end

	table.sort(buttonSet, sortFunc)
	LogOverlay.Windower.totalPages = LogOverlay.gridAlign(buttonSet, x, y, itemWidth, itemHeight, horizontalSpacer, verticalSpacer, true)
	LogOverlay.Windower.currentPage = 1
	LogOverlay.Buttons.CurrentPage:updateText()
end

-- Organizes a list of buttons in a row by column fashion based on (x,y,w,h) and what page they should display on.
-- Returns total pages
function LogOverlay.gridAlign(buttonList, startX, startY, width, height, colSpacer, rowSpacer, listVerticallyFirst)
	listVerticallyFirst = listVerticallyFirst == true
	local offsetX, offsetY = 0, 0
	local maxWidth = Constants.SCREEN.WIDTH - LogOverlay.margin
	local maxHeight = Constants.SCREEN.HEIGHT - LogOverlay.margin -- - 10 -- 10 padding near bottom for filter options
	local maxItemSize = 0

	local itemCount = 0
	local itemsPerPage = nil
	for _, button in ipairs(buttonList) do
		if button:includeInGrid() then
			local w, h, extraX, extraY = width, height, 0, 0
			if button.dimensions ~= nil then
				w = button.dimensions.width or width or 40
				h = button.dimensions.height or height or 40
				extraX = button.dimensions.extraX or 0
				extraY = button.dimensions.extraY or 0
			end

			if listVerticallyFirst then
				-- Check if new height requires starting a new column
				if (startY + offsetY + h) > maxHeight then
					offsetX = offsetX + maxItemSize + colSpacer
					offsetY = 0
					maxItemSize = 0
				end
				-- Check if new width requires starting a new page
				if (startX + offsetX + w) > maxWidth then
					offsetX, offsetY, maxItemSize = 0, 0, 0
					if itemsPerPage == nil then
						itemsPerPage = itemCount
					end
				end
			else
				-- Check if new width requires starting a new row
				if (startX + offsetX + w) > maxWidth then
					offsetX = 0
					offsetY = offsetY + maxItemSize + rowSpacer
					maxItemSize = 0
				end
				-- Check if new height requires starting a new page
				if (startY + offsetY + h) > maxHeight then
					offsetX, offsetY, maxItemSize = 0, 0, 0
					if itemsPerPage == nil then
						itemsPerPage = itemCount
					end
				end
			end

			itemCount = itemCount + 1
			local x = startX + offsetX + extraX
			local y = startY + offsetY + extraY
			if button.type == Constants.ButtonTypes.POKEMON_ICON then
				button.clickableArea = { x, y + 4, w, h - 4 }
			end
			button.box = { x, y, w, h }
			if itemsPerPage == nil then
				button.pageVisible = 1
			else
				button.pageVisible = math.ceil(itemCount / itemsPerPage)
			end

			if listVerticallyFirst then
				if w > maxItemSize then
					maxItemSize = w
				end
				offsetY = offsetY + h + rowSpacer
			else
				if h > maxItemSize then
					maxItemSize = h
				end
				offsetX = offsetX + w + colSpacer
			end

		else
			button.pageVisible = -1
		end
	end

	-- Return number of items per page, total pages
	if itemsPerPage == nil then
		return 1
	else
		return math.ceil(itemCount / itemsPerPage)
	end
end

function LogOverlay.buildPokemonZoomButtons(data)
    LogOverlay.TemporaryButtons = {}
    LogOverlay.currentPreEvoSet = 1
	LogOverlay.currentEvoSet = 1

	local offsetX, offsetY
	if data.p.abilities[1] == data.p.abilities[2] then
		data.p.abilities[2] = nil
	end

	local abilityButtonArea ={
		x=LogOverlay.margin + 1,
		y=LogOverlay.tabHeight + 13,
		w=60,
		h=Constants.SCREEN.LINESPACING*2
	}

	-- ABILITIES
	offsetY = 0
	for i, abilityId in ipairs(data.p.abilities) do
		local btnText
		if AbilityData.isValid(abilityId) then
			btnText = string.format("%s: %s", i, AbilityData.Abilities[abilityId].name)
		else
			btnText = Constants.BLANKLINE
		end
		local abilityBtn = {
			type = Constants.ButtonTypes.NO_BORDER,
			text = btnText,
			textColor = "Lower box text",
			abilityId = abilityId,
			tab = LogOverlay.Tabs.POKEMON_ZOOM,
			box = { abilityButtonArea.x, abilityButtonArea.y + offsetY, 60, 11 },
			isVisible = function(self) return LogOverlay.currentTab == self.tab end,
			onClick = function(self)
				if AbilityData.isValid(abilityId) then
					InfoScreen.changeScreenView(InfoScreen.Screens.ABILITY_INFO, self.abilityId) -- implied redraw
				end
			end,
		}
		table.insert(LogOverlay.TemporaryButtons, abilityBtn)
		offsetY = offsetY + Constants.SCREEN.LINESPACING
	end


	local evoMethods = Utils.getShortenedEvolutionsInfo(PokemonData.Pokemon[data.p.id].evolution) or {}

	local preEvoList = {}
	local evoList = {}
	local hasPrevEvo = Options["Show Pre Evolutions"] and #data.p.prevos > 0
	if hasPrevEvo then
		-- Add prevos to list
		for i, prev in ipairs(data.p.prevos) do
			table.insert(preEvoList, {
				name = PokemonData.Pokemon[prev.id].name,
				id = prev.id
			})
		end
	end

	local hasEvo = #data.p.evos > 0 or hasPrevEvo

	if hasEvo then
        -- Add evos to list
        for i, evoInfo in ipairs(data.p.evos) do
            table.insert(evoList,
                {
                    name = PokemonData.Pokemon[evoInfo.id].name,
                    id = evoInfo.id,
                    method = evoMethods[i]
                })
        end
        -- At evo methods to list
    end
	-- Pre-evos
	local pokemonIconSize = 32
	local pokemonIconSpacing = 4
	local evoLabelTextHeight = 7
	local evoArrowSize = 10

	local pokemonIconRange = {
		x = LogOverlay.margin + 75,
		y = LogOverlay.tabHeight - 2,
		w = function(self) return Constants.SCREEN.WIDTH - self.x - LogOverlay.margin - 1 end,
		h = pokemonIconSize + evoLabelTextHeight,
	}

	for i, preEvo in ipairs(preEvoList) do

		local evoText = ""
		-- Get pre-evos list of evos
		local preEvoEvoMethodList = Utils.getShortenedEvolutionsInfo(PokemonData.Pokemon[preEvo.id].evolution)
		local preEvoEvoMonList = RandomizerLog.Data.Pokemon[preEvo.id].Evolutions

		-- Find the evo that matches the current pokemon
		for j, evo in ipairs(preEvoEvoMonList) do
			if evo == data.p.id then
				evoText = preEvoEvoMethodList[j]
			end
		end
		-- If no match, use the first evo method
		if not evoText then
			evoText = preEvoEvoMethodList[1]
		end
		local x = pokemonIconRange.x
		local y = pokemonIconRange.y
		local preEvoButton = {
			textColor = "Lower box text",
			text = evoText,
			type = Constants.ButtonTypes.POKEMON_ICON,
			pokemonID = preEvo.id,
			clickableArea = { x, y, pokemonIconSize, pokemonIconSize + evoLabelTextHeight },
			box = { x, y, pokemonIconSize, pokemonIconSize },
			preEvoSet = i,
			isVisible = function(self)
				return self.preEvoSet == LogOverlay.currentPreEvoSet and
					LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM
			end,
			getIconPath = function(self)
				local iconset = Options.IconSetMap[Options["Pokemon icon set"]]
				return FileManager.buildImagePath(iconset.folder, tostring(self.pokemonID), iconset.extension)
			end,
			onClick = function(self)
				if PokemonData.isValid(self.pokemonID) then
					LogOverlay.Windower:changeTab(LogOverlay.Tabs.POKEMON_ZOOM, 1, 1, self.pokemonID)
					InfoScreen.changeScreenView(InfoScreen.Screens.POKEMON_INFO, self.pokemonID)
				end
			end,
			draw = function(self, shadowcolor)
				local evoTextSize = Utils.calcWordPixelLength(self.text or "")
				-- Center text
				local centeringOffsetX = math.max(self.box[3] / 2 - evoTextSize / 2, 0)
				local textX = self.box[1] + centeringOffsetX + pokemonIconSize + pokemonIconSpacing + evoArrowSize
				local textY = self.box[2] + self.box[4] + 2
				Drawing.drawText(textX, textY, self.text, Theme.COLORS[self.textColor], shadowcolor)
			end
		}
		table.insert(LogOverlay.TemporaryButtons, preEvoButton)
	end

	-- Main pokemon icon
	local mainPokemonBox = {
		pokemonIconRange.x,
		pokemonIconRange.y,
		pokemonIconSize,
		pokemonIconSize,
	}
	if hasPrevEvo then
		mainPokemonBox[1] = mainPokemonBox[1] + pokemonIconSize + pokemonIconSpacing + evoArrowSize
		LogOverlay.evosPerSet = 2
	else
		LogOverlay.evosPerSet = 3
	end
	local viewedPokemonIcon = {
		type = Constants.ButtonTypes.POKEMON_ICON,
		pokemonID = data.p.id,
		tab = LogOverlay.Tabs.POKEMON_ZOOM,
		box = mainPokemonBox,
		clickableArea = {
			mainPokemonBox[1],
			mainPokemonBox[2],
			mainPokemonBox[3],
			mainPokemonBox[4] + evoLabelTextHeight
		},
		isVisible = function(self) return LogOverlay.currentTab == self.tab end,
		getIconPath = function(self)
			local iconset = Options.IconSetMap[Options["Pokemon icon set"]]
			return FileManager.buildImagePath(iconset.folder, tostring(self.pokemonID), iconset.extension)
		end,
		onClick = function(self)
			if PokemonData.isValid(self.pokemonID) then
				InfoScreen.changeScreenView(InfoScreen.Screens.POKEMON_INFO, self.pokemonID)
			end
		end,

		draw = function(self)
			if Options["Show Pre Evolutions"] and hasEvo then

				Drawing.drawSelectionIndicators(
					self.box[1],
					self.box[2] - 1 + evoLabelTextHeight,
					pokemonIconSize - 1,
					pokemonIconSize - 4,
					Theme.COLORS["Intermediate text"],
					1,
					5,
					1
				)
			end
		end
	}
	table.insert(LogOverlay.TemporaryButtons, viewedPokemonIcon)

	-- Evo icons
	local iconset = 1
	local xOffset = evoArrowSize
	for i, evo in ipairs(evoList) do
		local evoBox = {
			xOffset + viewedPokemonIcon.box[1] + pokemonIconSize + pokemonIconSpacing,
			pokemonIconRange.y,
			pokemonIconSize,
			pokemonIconSize,
		}
		-- If no evo method is given, use the first one
		if not evo.method then
			evo.method = evoList[1].method
		end
		local evoButton = {
			textColor = "Lower box text",
			text = evo.method,
			type = Constants.ButtonTypes.POKEMON_ICON,
			pokemonID = evo.id,
			clickableArea = { evoBox[1], evoBox[2], evoBox[3], evoBox[4] + evoLabelTextHeight },
			box = evoBox,
			evoSet = iconset,
			isVisible = function(self)
				return self.evoSet == LogOverlay.currentEvoSet and
					LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM
			end,
			getIconPath = function(self)
				local iconset = Options.IconSetMap[Options["Pokemon icon set"]]
				return FileManager.buildImagePath(iconset.folder, tostring(self.pokemonID), iconset.extension)
			end,
			onClick = function(self)
				if PokemonData.isValid(self.pokemonID) then
					LogOverlay.Windower:changeTab(LogOverlay.Tabs.POKEMON_ZOOM, 1, 1, self.pokemonID)
					InfoScreen.changeScreenView(InfoScreen.Screens.POKEMON_INFO, self.pokemonID)
				end
			end,
			draw = function(self, shadowcolor)
				local evoTextSize = Utils.calcWordPixelLength(self.text or "")
				-- Center text
				local centeringOffsetX = math.max(self.box[3] / 2 - evoTextSize / 2, 0)
				Drawing.drawText(self.box[1] + centeringOffsetX, self.box[2] + self.box[4] + 2, self.text,
					Theme.COLORS[self.textColor], shadowcolor)
			end
		}
		table.insert(LogOverlay.TemporaryButtons, evoButton)
		if i % LogOverlay.evosPerSet == 0 then
			iconset = iconset + 1
			xOffset = evoArrowSize
		else
			xOffset = xOffset + pokemonIconSize + (pokemonIconSpacing / 2)
		end
	end
	local evoArrowX = viewedPokemonIcon.box[1] + pokemonIconSpacing / 2 + pokemonIconSize
	-- EVOLUTION ARROW
	if hasEvo then
		local evoArrow = {
			type = Constants.ButtonTypes.PIXELIMAGE,
			image = Constants.PixelImages.RIGHT_ARROW,
			textColor = "Lower box text",
			box = {
				evoArrowX,
				pokemonIconRange.y + (pokemonIconRange.h / 2) - 3,
				evoArrowSize,
				evoArrowSize
			},
			isVisible = function() return LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM and #data.p.evos > 0 end,
			onClick = function(self)
				LogOverlay.currentEvoSet = LogOverlay.currentEvoSet % math.ceil(#data.p.evos / LogOverlay.evosPerSet) + 1
				Program.redraw(true)
			end,
		}
		table.insert(LogOverlay.TemporaryButtons, evoArrow)
	end
	local prevEvoArrowX = viewedPokemonIcon.box[1] - pokemonIconSpacing / 2 - evoArrowSize
	-- PREV EVOLUTION ARROW
	if hasPrevEvo then
		local prevEvoArrow = {
			type = Constants.ButtonTypes.PIXELIMAGE,
			image = Constants.PixelImages.RIGHT_ARROW,
			textColor = "Lower box text",
			box = {
				prevEvoArrowX,
				pokemonIconRange.y + (pokemonIconRange.h / 2) - 3,
				evoArrowSize,
				evoArrowSize
			},
			isVisible = function() return LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM and #data.p.prevos > 0 end,
			onClick = function(self)
				LogOverlay.currentPreEvoSet = LogOverlay.currentPreEvoSet - 1
				if LogOverlay.currentPreEvoSet <= 0 then
					LogOverlay.currentPreEvoSet = math.ceil(#data.p.prevos / LogOverlay.prevEvosPerSet)
				end
				Program.redraw(true)
			end,
		}
		table.insert(LogOverlay.TemporaryButtons, prevEvoArrow)
	end

	-- Chevrons to indicate current evoset and prevo set
	local chevronSizeX = 2
	local chevronSizeY = 4
	local chevronSpacing = 0
	local chevronThickness = 2


	if #evoList > LogOverlay.evosPerSet then
		local evosets = math.ceil(#evoList / LogOverlay.evosPerSet)
		local chevronsTotalWidth = (chevronSizeX + chevronThickness + chevronSpacing + 1) * evosets - chevronSpacing

		local centerX = evoArrowX + evoArrowSize / 2 - 1 -- -1 to center it better
		local startX = centerX - (chevronsTotalWidth / 2)

		local chevronBox = {
			startX,
			viewedPokemonIcon.box[2] + pokemonIconSize + Constants.Font.SIZE - ((chevronSizeY + 1) / 2),
			chevronsTotalWidth,
			chevronSizeY
		}

		local chevronButton = {
			type = Constants.ButtonTypes.NORMAL,
			box = chevronBox,
			clickableArea = {
				startX - (chevronSpacing + 1),
				chevronBox[2] - (chevronSpacing + 1),
				chevronsTotalWidth + (chevronSpacing + 1) * 2,
				chevronSizeY + (chevronSpacing + 1) * 2
			},
			color = function(i)
				if i == LogOverlay.currentEvoSet then
					return Theme.COLORS["Positive text"]
				end
				return Theme.COLORS["Lower box text"]
			end,
			isVisible = function()
				return LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM and
					#data.p.evos > LogOverlay.evosPerSet
			end,
			draw = function(self)
				for i = 1, evosets do
					Drawing.drawChevron(
						startX + ((i - 1) * (chevronSizeX + chevronSpacing + chevronThickness)),
						self.box[2],
						chevronSizeX,
						chevronSizeY,
						chevronThickness,
						"right",
						self.color(i)
					)
				end
			end,
			onClick = function(self)
				LogOverlay.currentEvoSet = LogOverlay.currentEvoSet + 1
				if LogOverlay.currentEvoSet > evosets then
					LogOverlay.currentEvoSet = 1
				end
				Program.redraw(true)
			end
		}

		table.insert(LogOverlay.TemporaryButtons, chevronButton)
	end
	if #preEvoList > LogOverlay.prevEvosPerSet then
		local prevosets = math.ceil(#preEvoList / LogOverlay.prevEvosPerSet)
		local chevronsTotalWidth = (chevronSizeX + chevronThickness + chevronSpacing + 1) * prevosets - chevronSpacing

		local centerX = prevEvoArrowX + evoArrowSize / 2 - 2 -- -2 to center it better for some reason
		local startX = centerX - (chevronsTotalWidth / 2)

		local chevronBox = {
			startX,
			viewedPokemonIcon.box[2] + pokemonIconSize + Constants.Font.SIZE - ((chevronSizeY + 1) / 2),
			chevronsTotalWidth,
			chevronSizeY
		}

		local chevronButton = {
			type = Constants.ButtonTypes.NORMAL,
			box = chevronBox,
			clickableArea = {
				startX - (chevronSpacing + 1),
				chevronBox[2] - (chevronSpacing + 1),
				chevronsTotalWidth + (chevronSpacing + 1) * 2,
				chevronSizeY + (chevronSpacing + 1) * 2
			},
			color = function(i)
				if i == LogOverlay.currentPreEvoSet then
					return Theme.COLORS["Positive text"]
				end
				return Theme.COLORS["Lower box text"]
			end,
			isVisible = function()
				return LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM and
					#data.p.prevos > LogOverlay.prevEvosPerSet
			end,
			draw = function(self)
				for i = 1, prevosets do
					Drawing.drawChevron(
						startX + ((i - 1) * (chevronSizeX + chevronSpacing + chevronThickness)),
						self.box[2],
						chevronSizeX,
						chevronSizeY,
						chevronThickness,
						"right",
						self.color(i)
					)
				end
			end,
			onClick = function(self)
				LogOverlay.currentPreEvoSet = LogOverlay.currentPreEvoSet + 1
				if LogOverlay.currentPreEvoSet > prevosets then
					LogOverlay.currentPreEvoSet = 1
				end
				Program.redraw(true)
			end
		}
		table.insert(LogOverlay.TemporaryButtons, chevronButton)
	end


	local movesColX = LogOverlay.margin + 118
	local movesRowY = LogOverlay.tabHeight + Utils.inlineIf(hasEvo, 42, 0)
	LogOverlay.PokemonMovesPagination.movesPerPage = Utils.inlineIf(hasEvo, 8, 12)

	local levelupMovesTab = {
		type = Constants.ButtonTypes.NO_BORDER,
		text = LogOverlay.Tabs.POKEMON_ZOOM_LEVELMOVES,
		textColor = "Lower box text",
		tab = LogOverlay.Tabs.POKEMON_ZOOM_LEVELMOVES,
		box = { movesColX, movesRowY, 60, 11 },
		isVisible = function(self) return LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM end,
		updateText = function(self)
			if LogOverlay.PokemonMovesPagination.currentTab == self.tab then
				self.text = string.format(LogOverlay.Labels.tabFormat, self.tab)
				self.textColor = "Intermediate text"
			else
				self.text = self.tab
				self.textColor = "Lower box text"
			end
		end,
		draw = function(self)
			-- Draw an underline if selected
			if self.textColor == "Intermediate text" then
				local x1, x2 = self.box[1] + 2, self.box[1] + self.box[3] - 1
				local y1, y2 = self.box[2] + self.box[4] - 1, self.box[2] + self.box[4] - 1
				gui.drawLine(x1, y1, x2, y2, Theme.COLORS[self.textColor])
			end
		end,
		onClick = function(self)
			if LogOverlay.PokemonMovesPagination.currentTab ~= self.tab then
				LogOverlay.PokemonMovesPagination:changeTab(self.tab)
				Program.redraw(true)
			end
		end,
	}
	local tmMovesTab = {
		type = Constants.ButtonTypes.NO_BORDER,
		text = LogOverlay.Tabs.POKEMON_ZOOM_TMMOVES,
		textColor = "Lower box text",
		tab = LogOverlay.Tabs.POKEMON_ZOOM_TMMOVES,
		box = { movesColX + 70, movesRowY, 41, 11 },
		isVisible = function(self) return LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM end,
		updateText = function(self)
			if LogOverlay.PokemonMovesPagination.currentTab == self.tab then
				self.text = string.format(LogOverlay.Labels.tabFormat, self.tab)
				self.textColor = "Intermediate text"
			else
				self.text = self.tab
				self.textColor = "Lower box text"
			end
		end,
		draw = function(self)
			-- Draw an underline if selected
			if self.textColor == "Intermediate text" then
				local x1, x2 = self.box[1] + 2, self.box[1] + self.box[3] - 1
				local y1, y2 = self.box[2] + self.box[4] - 1, self.box[2] + self.box[4] - 1
				gui.drawLine(x1, y1, x2, y2, Theme.COLORS[self.textColor])
			end
		end,
		onClick = function(self)
			if LogOverlay.PokemonMovesPagination.currentTab ~= self.tab then
				LogOverlay.PokemonMovesPagination:changeTab(self.tab)
				Program.redraw(true)
			end
		end,
	}
	table.insert(LogOverlay.TemporaryButtons, levelupMovesTab)
	table.insert(LogOverlay.TemporaryButtons, tmMovesTab)

	local moveCategoryOffset = 90

	-- LEARNABLE MOVES
	offsetY = 0
	for i, moveInfo in ipairs(data.p.moves) do
		local moveColor = Utils.inlineIf(moveInfo.isstab, "Positive text", "Lower box text")
		local moveBtn = {
			type = Constants.ButtonTypes.NO_BORDER,
			text = string.format("%02d  %s", moveInfo.level, moveInfo.name),
			textColor = moveColor,
			moveId = moveInfo.id,
			tab = LogOverlay.Tabs.POKEMON_ZOOM_LEVELMOVES,
			pageVisible = math.ceil(i / LogOverlay.PokemonMovesPagination.movesPerPage),
			box = { movesColX, movesRowY + 13 + offsetY + Utils.inlineIf(hasEvo, 0, -2), 80, 11 },
			isVisible = function(self) return LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM and LogOverlay.PokemonMovesPagination.currentTab == self.tab and LogOverlay.PokemonMovesPagination.currentPage == self.pageVisible end,
			draw = function (self, shadowcolor)
				if Options["Show physical special icons"] and MoveData.isValid(self.moveId) then
					local move = MoveData.Moves[self.moveId]
					if move.category == MoveData.Categories.PHYSICAL then
						Drawing.drawImageAsPixels(Constants.PixelImages.PHYSICAL, self.box[1] + moveCategoryOffset, self.box[2] + 2, { Theme.COLORS[self.textColor] }, shadowcolor)
					elseif move.category == MoveData.Categories.SPECIAL then
						Drawing.drawImageAsPixels(Constants.PixelImages.SPECIAL, self.box[1] + moveCategoryOffset, self.box[2] + 2, { Theme.COLORS[self.textColor] }, shadowcolor)
					end
				end
			end,
			onClick = function(self)
				if MoveData.isValid(self.moveId) then
					InfoScreen.changeScreenView(InfoScreen.Screens.MOVE_INFO, self.moveId) -- implied redraw
				end
			end,
		}
		table.insert(LogOverlay.TemporaryButtons, moveBtn)
		if i % LogOverlay.PokemonMovesPagination.movesPerPage == 0 then
			offsetY = 0
		else
			offsetY = offsetY + Constants.SCREEN.LINESPACING
		end
	end

	-- LEARNABLE TMS
	local sortGymsFirst = function(a, b) return (a.gymNum * 1000 + a.tm) < (b.gymNum * 1000 + b.tm) end
	table.sort(data.p.tmmoves, sortGymsFirst)

	-- Add a spacer to separate Gym TMs from regular TMs
	for i, tmInfo in ipairs(data.p.tmmoves) do
		if tmInfo.gymNum > 8 then
			if i ~= 1 then
				table.insert(data.p.tmmoves, i, { label = LogOverlay.Labels.otherTMs})
				table.insert(data.p.tmmoves, 1, { label = LogOverlay.Labels.gymTMs})
				break
			else
				table.insert(data.p.tmmoves, 1, { label = LogOverlay.Labels.otherTMs})
				break
			end
		end
	end

	offsetY = 0
	for i, tmInfo in ipairs(data.p.tmmoves) do
		local moveText, moveColor
		if tmInfo.label ~= nil then
			moveText = tmInfo.label
			moveColor = "Intermediate text"
		else
			moveText = string.format("TM%02d  %s", tmInfo.tm, tmInfo.moveName)
			if tmInfo.isstab then
				moveColor = "Positive text"
			else
				moveColor = "Lower box text"
			end
		end
		local moveBtn = {
			type = Constants.ButtonTypes.NO_BORDER,
			text = moveText,
			textColor = moveColor,
			moveId = tmInfo.moveId,
			tab = LogOverlay.Tabs.POKEMON_ZOOM_TMMOVES,
			pageVisible = math.ceil(i / LogOverlay.PokemonMovesPagination.movesPerPage),
			box = { movesColX, movesRowY + 13 + offsetY + Utils.inlineIf(hasEvo, 0, -2), 80, 11 },
			isVisible = function(self) return LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM and LogOverlay.PokemonMovesPagination.currentTab == self.tab and LogOverlay.PokemonMovesPagination.currentPage == self.pageVisible end,
			draw = function (self, shadowcolor)
				if Options["Show physical special icons"] and MoveData.isValid(self.moveId) then
					local move = MoveData.Moves[self.moveId]
					if move.category == MoveData.Categories.PHYSICAL then
						Drawing.drawImageAsPixels(Constants.PixelImages.PHYSICAL, self.box[1] + moveCategoryOffset, self.box[2] + 2, { Theme.COLORS[self.textColor] }, shadowcolor)
					elseif move.category == MoveData.Categories.SPECIAL then
						Drawing.drawImageAsPixels(Constants.PixelImages.SPECIAL, self.box[1] + moveCategoryOffset, self.box[2] + 2, { Theme.COLORS[self.textColor] }, shadowcolor)
					end
				end
			end,
			onClick = function(self)
				if MoveData.isValid(self.moveId) then
					InfoScreen.changeScreenView(InfoScreen.Screens.MOVE_INFO, self.moveId) -- implied redraw
				end
			end,
		}
		table.insert(LogOverlay.TemporaryButtons, moveBtn)
		if i % LogOverlay.PokemonMovesPagination.movesPerPage == 0 then
			offsetY = 0
		else
			offsetY = offsetY + Constants.SCREEN.LINESPACING
		end
	end

	-- UP/DOWN PAGING ARROWS
	local upArrow = {
		type = Constants.ButtonTypes.PIXELIMAGE,
		image = Constants.PixelImages.UP_ARROW,
		textColor = "Lower box text",
		box = { movesColX + 107, movesRowY + 24 + Utils.inlineIf(hasEvo, 0, 10), 10, 10 },
		isVisible = function() return LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM and LogOverlay.PokemonMovesPagination.totalPages > 1 end,
		onClick = function(self)
			LogOverlay.PokemonMovesPagination:prevPage()
			Program.redraw(true)
		end,
	}
	local downArrow = {
		type = Constants.ButtonTypes.PIXELIMAGE,
		image = Constants.PixelImages.DOWN_ARROW,
		textColor = "Lower box text",
		box = { movesColX + 107, movesRowY + 81 + Utils.inlineIf(hasEvo, 0, 30), 10, 10 },
		isVisible = function() return LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM and LogOverlay.PokemonMovesPagination.totalPages > 1 end,
		onClick = function(self)
			LogOverlay.PokemonMovesPagination:nextPage()
			Program.redraw(true)
		end,
	}
	table.insert(LogOverlay.TemporaryButtons, upArrow)
	table.insert(LogOverlay.TemporaryButtons, downArrow)

	LogOverlay.PokemonMovesPagination.totalLearnedMoves = #data.p.moves
	LogOverlay.PokemonMovesPagination.totalTMMoves = #data.p.tmmoves
	LogOverlay.PokemonMovesPagination:changeTab(LogOverlay.Tabs.POKEMON_ZOOM_LEVELMOVES)
end

function LogOverlay.buildTrainerZoomButtons(data)
	LogOverlay.TemporaryButtons = {}

	local partyListX, partyListY = LogOverlay.margin + 1, LogOverlay.tabHeight + 76
	local startX, startY = LogOverlay.margin + 60, LogOverlay.tabHeight + 2
	local offsetX, offsetY = 0, 0
	local colOffset, rowOffset = 86, 49 -- 2nd column, and 2nd/3rd rows
	for i, partyPokemon in ipairs(data.p or {}) do
		-- PARTY POKEMON
		local pokemonNameButton = {
			type = Constants.ButtonTypes.NO_BORDER,
			text = string.format("%s. %s", i, partyPokemon.name), -- e.g. "1. Shuckle"
			textColor = "Lower box text",
			pokemonID = partyPokemon.id,
			tab = LogOverlay.Tabs.TRAINER_ZOOM,
			box = { partyListX, partyListY, 60, 11 },
			isVisible = function(self) return LogOverlay.currentTab == self.tab end,
			onClick = function(self)
				if PokemonData.isValid(self.pokemonID) then
					LogOverlay.Windower:changeTab(LogOverlay.Tabs.POKEMON_ZOOM, 1, 1, self.pokemonID)
					InfoScreen.changeScreenView(InfoScreen.Screens.POKEMON_INFO, self.pokemonID) -- implied redraw
				end
			end,
		}
		partyListY = partyListY + Constants.SCREEN.LINESPACING
		local pokemonIconButton = {
			type = Constants.ButtonTypes.POKEMON_ICON,
			pokemonID = partyPokemon.id,
			text = string.format(LogOverlay.Labels.partyPokemonLevelFormat, partyPokemon.level),
			tab = LogOverlay.Tabs.TRAINER_ZOOM,
			clickableArea = { startX + offsetX, startY + offsetY, 32, 29, },
			box = { startX + offsetX, startY + offsetY - 4, 32, 32, },
			isVisible = function(self) return LogOverlay.currentTab == self.tab end,
			getIconPath = function(self)
				local iconset = Options.IconSetMap[Options["Pokemon icon set"]]
				return FileManager.buildImagePath(iconset.folder, tostring(self.pokemonID), iconset.extension)
			end,
			onClick = function(self)
				if PokemonData.isValid(self.pokemonID) then
					LogOverlay.Windower:changeTab(LogOverlay.Tabs.POKEMON_ZOOM, 1, 1, self.pokemonID)
					InfoScreen.changeScreenView(InfoScreen.Screens.POKEMON_INFO, self.pokemonID) -- implied redraw
				end
			end,
		}
		table.insert(LogOverlay.TemporaryButtons, pokemonNameButton)
		table.insert(LogOverlay.TemporaryButtons, pokemonIconButton)

		-- helditem = partyMon.helditem ???

		-- PARTY POKEMON's MOVES
		local moveOffsetX = startX + offsetX + 30
		local moveOffsetY = startY + offsetY
		for _, moveInfo in ipairs(partyPokemon.moves or {}) do
			local moveBtn = {
				type = Constants.ButtonTypes.NO_BORDER,
				text = moveInfo.name,
				textColor = "Lower box text",
				moveId = moveInfo.moveId,
				tab = LogOverlay.Tabs.TRAINER_ZOOM,
				box = { moveOffsetX, moveOffsetY, 60, 11 },
				isVisible = function(self) return LogOverlay.currentTab == self.tab end,
				onClick = function(self)
					if MoveData.isValid(self.moveId) then
						InfoScreen.changeScreenView(InfoScreen.Screens.MOVE_INFO, self.moveId) -- implied redraw
					end
				end,
			}
			table.insert(LogOverlay.TemporaryButtons, moveBtn)
			moveOffsetY = moveOffsetY + Constants.SCREEN.LINESPACING - 1
		end

		if i % 2 == 1 then
			offsetX = offsetX + colOffset
		else
			offsetX = 0
			offsetY = offsetY + rowOffset
		end
	end
end

function LogOverlay.buildTMGymButtons()
	LogOverlay.realignTMGrid(LogOverlay.NavFilters.TMs[2].label, LogOverlay.NavFilters.TMs[2].sortFunc)

	local gymColOffsetX = 80 + 17
	for _, tmButton in pairs(LogOverlay.PagedButtons.TMs) do
		if tmButton.group == "Gym TMs" then
			local badgeName = GameSettings.badgePrefix .. "_badge" .. tmButton.gymNumber
			local badgeImage = FileManager.buildImagePath(FileManager.Folders.Badges, badgeName, FileManager.Extensions.BADGE)
			local gymLabel = string.format("Gym %s", tmButton.gymNumber or 0)

			local gymButton = {
				type = Constants.ButtonTypes.NO_BORDER,
				text = tmButton.gymLeader,
				textColor = tmButton.textColor,
				trainerId = tmButton.trainerId,
				group = tmButton.group,
				tab = LogOverlay.Tabs.TMS,
				box = { tmButton.box[1] + gymColOffsetX, tmButton.box[2], 90, 11 },
				isVisible = function(self) return LogOverlay.currentTab == self.tab and LogOverlay.Windower.filterGrid == self.group end,
				draw = function(self, shadowcolor)
					-- Draw badge icon to the left of the TM move
					gui.drawImage(badgeImage, tmButton.box[1] - 18, tmButton.box[2] - 2)
					-- Draw the gym leader name and gym # to the right of the TM move
					Drawing.drawText(self.box[1] + 55, self.box[2], gymLabel, Theme.COLORS[self.textColor], shadowcolor)
				end,
				onClick = function(self)
					LogOverlay.Windower:changeTab(LogOverlay.Tabs.TRAINER_ZOOM, 1, 1, self.trainerId)
					Program.redraw(true)
					-- InfoScreen.changeScreenView(InfoScreen.Screens.TRAINER_INFO, self.trainerId) -- TODO: (future feature) implied redraw
				end,
			}
			table.insert(LogOverlay.Buttons, gymButton)
		end
	end
end

-- For showing what's highlighted and updating the page #
function LogOverlay.refreshTabBar()
	for _, button in pairs(LogOverlay.TabBarButtons) do
		if button.updateText ~= nil then
			button:updateText()
		end
	end
end

function LogOverlay.refreshInnerButtons()
	for _, button in pairs(LogOverlay.Buttons) do
		if button.updateText ~= nil then
			button:updateText()
		end
	end
	for _, button in pairs(LogOverlay.TemporaryButtons) do
		if button.updateText ~= nil then
			button:updateText()
		end
	end
end

function LogOverlay.openRandomizerShareWindow()
	local form = Utils.createBizhawkForm("Share Randomizer Seed", 515, 235)

	local newline = "\r\n"
	local randomizerInfo = {
		{
			label = Constants.Words.POKEMON .. " Game:",
			value = RandomizerLog.Data.Settings.Game or Constants.BLANKLINE,
		},
		{
			label = "Randomizer Version:",
			value = RandomizerLog.Data.Settings.Version or Constants.BLANKLINE,
		},
		{
			label = "Random Seed:",
			value = RandomizerLog.Data.Settings.RandomSeed or Constants.BLANKLINE,
		},
		{
			label = newline .. "Settings String:",
			value = RandomizerLog.Data.Settings.SettingsString or Constants.BLANKLINE,
		},
	}
	local shareExport = {}
	for _, infoSection in ipairs(randomizerInfo) do
		table.insert(shareExport, string.format("%s %s", infoSection.label, infoSection.value))
	end

	forms.label(form, LogOverlay.Labels.shareSeed, 9, 10, 495, 20)
	forms.textbox(form, table.concat(shareExport, " " .. newline), 480, 120, nil, 10, 35, true, false, "Vertical")
	forms.button(form, "Close", function()
		forms.destroy(form)
	end, 212, 165)
end

-- USER INPUT FUNCTIONS
function LogOverlay.checkInput(xmouse, ymouse)
	if not LogOverlay.isDisplayed then return end

	-- Order here matters
	Input.checkButtonsClicked(xmouse, ymouse, LogOverlay.TemporaryButtons)
	Input.checkButtonsClicked(xmouse, ymouse, LogOverlay.Buttons)
	Input.checkButtonsClicked(xmouse, ymouse, LogOverlay.TabBarButtons)
	for _, buttonSet in pairs(LogOverlay.PagedButtons) do
		Input.checkButtonsClicked(xmouse, ymouse, buttonSet)
	end
end

-- DRAWING FUNCTIONS
function LogOverlay.drawScreen()
	if not LogOverlay.isDisplayed then return end

	Drawing.drawBackgroundAndMargins(0, 0, Constants.SCREEN.WIDTH, Constants.SCREEN.HEIGHT)

	local box = {
		x = LogOverlay.margin,
		y = LogOverlay.tabHeight,
		width = Constants.SCREEN.WIDTH - (LogOverlay.margin * 2),
		height = Constants.SCREEN.HEIGHT - LogOverlay.tabHeight - LogOverlay.margin - 1,
	}

	local borderColor, shadowcolor
	if LogOverlay.currentTab == LogOverlay.Tabs.POKEMON then
		borderColor, shadowcolor = LogOverlay.drawPokemonTab(box.x, box.y, box.width, box.height)
		-- gui.drawLine(box.x + 2, box.y - 2, box.x + 40, box.y - 2, Theme.COLORS[Theme.headerHighlightKey])
	elseif LogOverlay.currentTab == LogOverlay.Tabs.TRAINER then
		borderColor, shadowcolor = LogOverlay.drawTrainersTab(box.x, box.y, box.width, box.height)
		-- gui.drawLine(box.x + 48, box.y - 2, box.x + 78, box.y - 2, Theme.COLORS[Theme.headerHighlightKey])
	elseif LogOverlay.currentTab == LogOverlay.Tabs.TMS then
		borderColor, shadowcolor = LogOverlay.drawTMsTab(box.x, box.y, box.width, box.height)
		-- gui.drawLine(box.x + 86, box.y - 2, box.x + 100, box.y - 2, Theme.COLORS[Theme.headerHighlightKey])
	elseif LogOverlay.currentTab == LogOverlay.Tabs.MISC then
		borderColor, shadowcolor = LogOverlay.drawMiscTab(box.x, box.y, box.width, box.height)
		-- gui.drawLine(box.x + 107, box.y - 2, box.x + 126, box.y - 2, Theme.COLORS[Theme.headerHighlightKey])
	elseif LogOverlay.currentTab == LogOverlay.Tabs.POKEMON_ZOOM then
		borderColor, shadowcolor = LogOverlay.drawPokemonZoomed(box.x, box.y, box.width, box.height)
	elseif LogOverlay.currentTab == LogOverlay.Tabs.TRAINER_ZOOM then
		borderColor, shadowcolor = LogOverlay.drawTrainerZoomed(box.x, box.y, box.width, box.height)
	end

	-- Draw tab dividers
	gui.drawLine(box.x, 1, box.x, box.y - 1, borderColor or Theme.COLORS["Upper box border"])
	gui.drawLine(box.x + 44, 1, box.x + 44, box.y - 1, borderColor or Theme.COLORS["Upper box border"])
	gui.drawLine(box.x + 82, 1, box.x + 82, box.y - 1, borderColor or Theme.COLORS["Header text"])
	gui.drawLine(box.x + 104, 1, box.x + 104, box.y - 1, borderColor or Theme.COLORS["Header text"])

	-- Draw all buttons
	local bgColor = Utils.calcShadowColor(Theme.COLORS["Main background"]) -- Note, "header text" doesn't do shadows for transparency bgs
	for _, button in pairs(LogOverlay.TabBarButtons) do
		Drawing.drawButton(button, bgColor)
	end
	for _, button in pairs(LogOverlay.Buttons) do
		-- The page display currently lives in the header
		if button == LogOverlay.Buttons.CurrentPage then
			Drawing.drawButton(button, bgColor)
		else
			Drawing.drawButton(button, shadowcolor)
		end
	end
end

-- Unsure if this will actually be needed, likely some of them
function LogOverlay.drawPokemonTab(x, y, width, height)
	local textColor = Theme.COLORS["Default text"]
	local borderColor = Theme.COLORS["Upper box border"]
	local fillColor = Theme.COLORS["Upper box background"]
	local shadowcolor = Utils.calcShadowColor(fillColor)
	gui.defaultTextBackground(fillColor)
	gui.drawRectangle(x, y, width, height, borderColor, fillColor)

	-- VISIBLE POKEMON ICONS
	for _, button in pairs(LogOverlay.PagedButtons.Pokemon) do
		-- First draw the Pokemon Icon
		Drawing.drawButton(button, shadowcolor)
		-- Then draw the text on top of it, with a background
		if button:isVisible() then
			local pokemonName = PokemonData.Pokemon[button.pokemonID].name
			gui.drawRectangle(button.box[1], button.box[2] + 1, 32, 9, fillColor, fillColor) -- cut-off top of icon
			Drawing.drawText(button.box[1] - 5, button.box[2], pokemonName, textColor, shadowcolor)
		end
	end

	return borderColor, shadowcolor
end

function LogOverlay.drawTrainersTab(x, y, width, height)
	local textColor = Theme.COLORS["Default text"]
	local highlightColor = Theme.COLORS["Intermediate text"]
	local borderColor = Theme.COLORS["Upper box border"]
	local fillColor = Theme.COLORS["Upper box background"]
	local shadowcolor = Utils.calcShadowColor(fillColor)
	gui.defaultTextBackground(fillColor)
	gui.drawRectangle(x, y, width, height, borderColor, fillColor)

	-- VISIBLE TRAINERS
	local bottomPadding = 9
	for _, button in pairs(LogOverlay.PagedButtons.Trainers) do
		Drawing.drawButton(button, shadowcolor)
		-- Then draw the text on top of it, with a background
		if button:isVisible() then
			if LogOverlay.debugTrainerIconBoxes then
				gui.drawRectangle(button.box[1], button.box[2], button.box[3], button.box[4], Theme.COLORS[Theme.headerHighlightKey])
			end

			-- Draw a centered box for the Trainer's name
			local nameWidth = Utils.calcWordPixelLength(button.text)
			local offsetX = button.box[1] + button.box[3] / 2 - nameWidth / 2
			local offsetY = button.box[2] + TrainerData.FileInfo.maxHeight - bottomPadding - (button.dimensions.extraY or 0)
			gui.drawRectangle(offsetX - 1, offsetY, nameWidth + 5, bottomPadding + 2, borderColor, fillColor)
			Drawing.drawText(offsetX, offsetY, button.text, textColor, shadowcolor)
			gui.drawRectangle(offsetX - 1, offsetY, nameWidth + 5, bottomPadding + 2, borderColor) -- to cutoff the shadows
		end
	end

	-- Draw group filters Label
	Drawing.drawText(LogOverlay.margin + 2, LogOverlay.tabHeight + 1, LogOverlay.Labels.filterBy, textColor, shadowcolor)

	return borderColor, shadowcolor
end

function LogOverlay.drawTMsTab(x, y, width, height)
	local textColor = Theme.COLORS["Default text"]
	local borderColor = Theme.COLORS["Upper box border"]
	local fillColor = Theme.COLORS["Upper box background"]
	local shadowcolor = Utils.calcShadowColor(fillColor)
	gui.defaultTextBackground(fillColor)
	gui.drawRectangle(x, y, width, height, borderColor, fillColor)

	-- VISIBLE TMS
	for _, button in pairs(LogOverlay.PagedButtons.TMs) do
		Drawing.drawButton(button, shadowcolor)
	end

	-- Draw group filters Label
	Drawing.drawText(LogOverlay.margin + 2, LogOverlay.tabHeight + 1, LogOverlay.Labels.filterBy, textColor, shadowcolor)

	return borderColor, shadowcolor
end

function LogOverlay.drawMiscTab(x, y, width, height)
	local textColor = Theme.COLORS["Default text"]
	local borderColor = Theme.COLORS["Upper box border"]
	local fillColor = Theme.COLORS["Upper box background"]
	local shadowcolor = Utils.calcShadowColor(fillColor)
	gui.defaultTextBackground(fillColor)
	gui.drawRectangle(x, y, width, height, borderColor, fillColor)

	local rInfo = {
		Game = {
			label = Constants.Words.POKEMON .. " Game:",
			value = RandomizerLog.Data.Settings.Game or Constants.BLANKLINE,
		},
		Version = {
			label = "Randomizer Version:",
			value = RandomizerLog.Data.Settings.Version or Constants.BLANKLINE,
		},
		Seed = {
			label = "Random Seed:",
			value = RandomizerLog.Data.Settings.RandomSeed or Constants.BLANKLINE,
		},
		Settings = {
			label = "Settings String:",
			value = RandomizerLog.Data.Settings.SettingsString or Constants.BLANKLINE,
		},
	}
	local offsetX = x + 3
	local offsetY = y + 3
	local rowSpacer = 3
	local colOffsetX = 100
	Drawing.drawText(offsetX, offsetY, rInfo.Game.label, textColor, shadowcolor)
	Drawing.drawText(offsetX + colOffsetX, offsetY, rInfo.Game.value, textColor, shadowcolor)
	offsetY = offsetY + Constants.SCREEN.LINESPACING + rowSpacer

	Drawing.drawText(offsetX, offsetY, rInfo.Version.label, textColor, shadowcolor)
	Drawing.drawText(offsetX + colOffsetX, offsetY, rInfo.Version.value, textColor, shadowcolor)
	offsetY = offsetY + Constants.SCREEN.LINESPACING + rowSpacer

	Drawing.drawText(offsetX, offsetY, rInfo.Seed.label, textColor, shadowcolor)
	Drawing.drawText(offsetX + colOffsetX, offsetY, rInfo.Seed.value, textColor, shadowcolor)
	offsetY = offsetY + Constants.SCREEN.LINESPACING + rowSpacer

	Drawing.drawText(offsetX, offsetY, rInfo.Settings.label, textColor, shadowcolor)
	offsetY = offsetY + Constants.SCREEN.LINESPACING + rowSpacer

	local settingsString = rInfo.Settings.value
	offsetX = offsetX + 8
	for i = 1, 999, 38 do
		if settingsString:sub(i, i + 37) == "" then
			break
		end
		Drawing.drawText(offsetX, offsetY, settingsString:sub(i, i + 37), textColor, shadowcolor)
		offsetY = offsetY + Constants.SCREEN.LINESPACING
	end
	offsetY = offsetY + 1
	offsetX = offsetX - 8

	return borderColor, shadowcolor
end
function LogOverlay.drawPokemonZoomed(x, y, width, height)
	local textColor = Theme.COLORS["Lower box text"]
	local borderColor = Theme.COLORS["Lower box border"]
	local fillColor = Theme.COLORS["Lower box background"]
	local shadowcolor = Utils.calcShadowColor(fillColor)
	gui.defaultTextBackground(fillColor)
	gui.drawRectangle(x, y, width, height, borderColor, fillColor)

	local pokemonID = LogOverlay.currentTabInfoId
	local data = LogOverlay.currentTabData
	if not PokemonData.isValid(pokemonID) then
		return borderColor, shadowcolor
	elseif data == nil then -- ideally this is done only once on tab change
		LogOverlay.currentTabData = DataHelper.buildPokemonLogDisplay(pokemonID)
		data = LogOverlay.currentTabData
	end

	-- POKEMON NAME
	Drawing.drawText(x + 3, y + 2, data.p.name:upper(), Theme.COLORS["Intermediate text"], shadowcolor)

	-- POKEMON TYPES
	-- Drawing.drawTypeIcon(data.p.types[1], x + 5, y + 13)
	-- if data.p.types[2] ~= data.p.types[1] then
	-- 	Drawing.drawTypeIcon(data.p.types[2], x + 5, y + 25)
	-- end

	local statBox = {
		x = x + 6,
		y = y + 53,
		width = 103,
		height = 68,
		barW = 8,
		labelW = 17,
	}
	-- Draw header for stat box
	local bstTotal = string.format(LogOverlay.Labels.bstTotalFormat, data.p.bst)
	Drawing.drawText(statBox.x, statBox.y - 11, LogOverlay.Labels.bstStatBox, textColor, shadowcolor)
	Drawing.drawText(statBox.x + statBox.width - 39, statBox.y - 11, bstTotal, textColor, shadowcolor)
	-- Draw stat box
	gui.drawRectangle(statBox.x, statBox.y, statBox.width, statBox.height, borderColor, fillColor)
	local quarterMark = statBox.height/4
	gui.drawLine(statBox.x - 2, statBox.y, statBox.x, statBox.y, borderColor)
	gui.drawLine(statBox.x + statBox.width, statBox.y, statBox.x + statBox.width + 2, statBox.y, borderColor)
	gui.drawLine(statBox.x - 1, statBox.y + quarterMark * 1, statBox.x, statBox.y + quarterMark * 1, borderColor)
	gui.drawLine(statBox.x + statBox.width, statBox.y + quarterMark * 1, statBox.x + statBox.width + 1, statBox.y + quarterMark * 1, borderColor)
	gui.drawLine(statBox.x - 2, statBox.y + quarterMark * 2, statBox.x, statBox.y + quarterMark * 2, borderColor)
	gui.drawLine(statBox.x + statBox.width, statBox.y + quarterMark * 2, statBox.x + statBox.width + 2, statBox.y + quarterMark * 2, borderColor)
	gui.drawLine(statBox.x - 1, statBox.y + quarterMark * 3, statBox.x, statBox.y + quarterMark * 3, borderColor)
	gui.drawLine(statBox.x + statBox.width, statBox.y + quarterMark * 3, statBox.x + statBox.width + 1, statBox.y + quarterMark * 3, borderColor)
	gui.drawLine(statBox.x - 2, statBox.y + statBox.height, statBox.x, statBox.y + statBox.height, borderColor)
	gui.drawLine(statBox.x + statBox.width, statBox.y + statBox.height, statBox.x + statBox.width + 2, statBox.y + statBox.height, borderColor)

	local statX = statBox.x + 1
	for _, statKey in ipairs(Constants.OrderedLists.STATSTAGES) do
		-- Draw the vertical bar
		local barH = math.floor(data.p[statKey] / 255 * (statBox.height - 2) + 0.5)
		local barY = statBox.y + statBox.height - barH - 1 -- -1/-2 for box pixel border margin
		local barColor
		if data.p[statKey] >= 180 then -- top ~70%
			barColor = Theme.COLORS["Positive text"]
		elseif data.p[statKey] <= 40 then -- bottom ~15%
			barColor = Theme.COLORS["Negative text"]
		else
			barColor = textColor
		end
		gui.drawRectangle(statX + (statBox.labelW - statBox.barW) / 2, barY, statBox.barW, barH, barColor, barColor)

		-- Draw the bar's label
		local statLabelOffsetX = (3 - string.len(statKey)) * 2
		local statValueOffsetX = (3 - string.len(tostring(data.p[statKey]))) * 2
		Drawing.drawText(statX + statLabelOffsetX, statBox.y + statBox.height + 1, Utils.firstToUpper(statKey), textColor, shadowcolor)
		Drawing.drawText(statX + statValueOffsetX, statBox.y + statBox.height + 11, data.p[statKey], barColor, shadowcolor)
		statX = statX + statBox.labelW
	end

	-- data.p.helditems -- unused

	for _, button in pairs(LogOverlay.TemporaryButtons) do
		Drawing.drawButton(button, shadowcolor)
	end

	return borderColor, shadowcolor
end

function LogOverlay.drawTrainerZoomed(x, y, width, height)
	local textColor = Theme.COLORS["Lower box text"]
	local borderColor = Theme.COLORS["Lower box border"]
	local fillColor = Theme.COLORS["Lower box background"]
	local shadowcolor = Utils.calcShadowColor(fillColor)
	gui.defaultTextBackground(fillColor)
	gui.drawRectangle(x, y, width, height, borderColor, fillColor)

	local trainerId = LogOverlay.currentTabInfoId
	local data = LogOverlay.currentTabData
	if RandomizerLog.Data.Trainers[trainerId] == nil then
		return borderColor, shadowcolor
	elseif data == nil then -- ideally this is done only once on tab change
		LogOverlay.currentTabData = DataHelper.buildTrainerLogDisplay(trainerId)
		data = LogOverlay.currentTabData
	end

	-- GYM LEADER BADGE
	local badgeOffsetX = 0
	if data.x.gymNumber ~= nil then
		badgeOffsetX = 3
		local badgeName = GameSettings.badgePrefix .. "_badge" .. data.x.gymNumber
		local badgeImage = FileManager.buildImagePath(FileManager.Folders.Badges, badgeName, FileManager.Extensions.BADGE)
		gui.drawImage(badgeImage, LogOverlay.margin + 1, LogOverlay.tabHeight + 1)
	end

	-- TRAINER NAME
	local nameWidth = Utils.calcWordPixelLength(data.t.name:upper())
	local nameOffsetX = (TrainerData.FileInfo.maxWidth - nameWidth) / 2 -- center the trainer name a bit
	Drawing.drawText(x + nameOffsetX + badgeOffsetX + 3, y + 2, data.t.name:upper(), Theme.COLORS["Intermediate text"], shadowcolor)

	-- TRAINER ICON
	local trainerIcon = FileManager.buildImagePath(FileManager.Folders.Trainers, data.t.filename, FileManager.Extensions.TRAINER)
	local iconWidth = TrainerData.FileInfo[data.t.filename].width
	local iconOffsetX = (TrainerData.FileInfo.maxWidth - iconWidth) / 2 -- center the trainer icon a bit
	gui.drawImage(trainerIcon, x + iconOffsetX + 3, y + 16)

	for _, button in pairs(LogOverlay.TemporaryButtons) do
		Drawing.drawButton(button, shadowcolor)
		-- Draw the Pokemon's level text below the icon
		if button:isVisible() and button.type == Constants.ButtonTypes.POKEMON_ICON then
			local levelOffsetX = button.box[1] + 5
			local levelOffsetY = button.box[2] + button.box[4] + 2
			Drawing.drawText(levelOffsetX, levelOffsetY, button.text, textColor, shadowcolor)
		end
	end

	return borderColor, shadowcolor
end

function LogOverlay.viewLogFile(postfix)
	local logpath = LogOverlay.getLogFileAutodetected(postfix)

	-- Check if there exists a parsed log with the same postfix as the one being requested
	local hasParsedThisLog = RandomizerLog.Data.Settings ~= nil and (RandomizerLog.loadedLogPath or ""):find(postfix, 1, true) ~= nil

	-- Only prompt for a new file if no autodetect and nothing has been parsed yet
	if logpath == nil and not hasParsedThisLog then
		logpath = LogOverlay.getLogFileFromPrompt()
	end

	LogOverlay.parseAndDisplay(logpath)
end

--- Attempts to determine the log file that matches the currently loaded rom. If not match or can't find, returns nil
--- @param postFix string The file's postFix, most likely FileManager.PostFixes.AUTORANDOMIZED or FileManager.PostFixes.PREVIOUSATTEMPT
--- @return string|nil
function LogOverlay.getLogFileAutodetected(postFix)
	postFix = postFix or FileManager.PostFixes.AUTORANDOMIZED

	local romname, rompath
	if Options["Use premade ROMs"] and Options.FILES["ROMs Folder"] ~= nil then
		-- First make sure the ROMs Folder ends with a slash
		if Options.FILES["ROMs Folder"]:sub(-1) ~= FileManager.slash then
			Options.FILES["ROMs Folder"] = Options.FILES["ROMs Folder"] .. FileManager.slash
		end

		romname = GameSettings.getRomName() or ""
		if postFix == FileManager.PostFixes.PREVIOUSATTEMPT then
			local currentRomPrefix = string.match(romname, '[^0-9]+') or ""
			local currentRomNumber = string.match(romname, '[0-9]+') or "0"
			-- Decrement to the previous ROM and determine its full file path
			local prevRomName = string.format(currentRomPrefix .. "%0" .. string.len(currentRomNumber) .. "d", tonumber(currentRomNumber) - 1)
			romname = prevRomName
		end

		rompath = Options.FILES["ROMs Folder"] .. romname .. FileManager.Extensions.GBA_ROM
		if not FileManager.fileExists(rompath) then
			romname = romname:gsub(" ", "_")
			rompath = Options.FILES["ROMs Folder"] .. romname .. FileManager.Extensions.GBA_ROM
		end
	elseif Options["Generate ROM each time"] then
		-- Filename of the AutoRandomized ROM is based on the settings file (for cases of playing Kaizo + Survival + Others)
		local quickloadFiles = Main.GetQuickloadFiles()
		local settingsFileName = FileManager.extractFileNameFromPath(quickloadFiles.settingsList[1] or "")
		romname = string.format("%s %s%s", settingsFileName, postFix, FileManager.Extensions.GBA_ROM)
		rompath = FileManager.prependDir(romname)
	end

	-- Check if the name of the rom being played on the emulator matches the name of the autodetected rom
	if Main.IsOnBizhawk() then
		local plainFormatter = function(filename)
			-- strip out any auto appended postfixes
			filename = filename:gsub(FileManager.PostFixes.AUTORANDOMIZED, "")
			filename = filename:gsub(FileManager.PostFixes.PREVIOUSATTEMPT, "")
			filename = filename:gsub("%.gba", "")
			filename = filename:gsub(" ", "_")
			filename = filename:gsub("%d", "")
			return filename:lower()
		end
		local loadedRomName = GameSettings.getRomName() or "N/A"
		loadedRomName = plainFormatter(loadedRomName .. FileManager.Extensions.GBA_ROM)
		local autodetectedName = plainFormatter(romname or "")
		if loadedRomName ~= autodetectedName then
			return nil
		end
	end

	-- Return the full file path of the log file, or nil if it can't be found
	return FileManager.getPathIfExists((rompath or "") .. FileManager.Extensions.RANDOMIZER_LOGFILE)
end

--- Prompts user to select a log file to parse
--- @return string|nil
function LogOverlay.getLogFileFromPrompt()
	local suggestedFileName = (GameSettings.getRomName() or "") .. FileManager.Extensions.RANDOMIZER_LOGFILE
	local filterOptions = "Randomizer Log (*.log)|*.log|All files (*.*)|*.*"

	local workingDir = FileManager.dir
	if workingDir ~= "" then
		workingDir = workingDir:sub(1, -2) -- remove trailing slash
	end

	Utils.tempDisableBizhawkSound()
	local filepath = forms.openfile(suggestedFileName, workingDir, filterOptions)
	if filepath == "" then
		filepath = nil
	end
	Utils.tempEnableBizhawkSound()

	return filepath
end

function LogOverlay.parseAndDisplay(logpath)
	-- Check for what log we're trying to display, and if it's already been parsed
	if logpath ~= nil and RandomizerLog.loadedLogPath ~= logpath then
		RandomizerLog.Data = {}
		RandomizerLog.loadedLogPath = logpath
	end

	-- If data has already been loaded and parsed, use that first, otherwise try parsing the provided log file
	if RandomizerLog.Data.Settings ~= nil then
		LogOverlay.isDisplayed = true
	else
		LogOverlay.isDisplayed = RandomizerLog.parseLog(logpath)
	end

	if LogOverlay.isDisplayed then
		LogOverlay.buildPagedButtons()
		LogOverlay.Windower:changeTab(LogOverlay.Tabs.POKEMON)

		local leadPokemon = Tracker.getPokemon(1, true) or Tracker.getDefaultPokemon()
		if PokemonData.isValid(leadPokemon.pokemonID) then
			LogOverlay.Windower:changeTab(LogOverlay.Tabs.POKEMON_ZOOM, 1, 1, leadPokemon.pokemonID)
			InfoScreen.changeScreenView(InfoScreen.Screens.POKEMON_INFO, leadPokemon.pokemonID)
		else
			InfoScreen.changeScreenView(InfoScreen.Screens.POKEMON_INFO, 1) -- Show Bulbasaur by default; implied redraw
		end
	end

	return LogOverlay.isDisplayed
end
