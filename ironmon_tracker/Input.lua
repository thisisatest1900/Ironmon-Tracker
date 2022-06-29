Input = {
	mousetab = {},
	mousetab_prev = {},
	joypad = {},
	noteForm = nil,
	currentColorPicker = nil,
}

function Input.update()
	if Input.currentColorPicker ~= nil then
		Input.currentColorPicker:handleInput()
	else
		Input.mousetab = input.getmouse()
		if Input.mousetab["Left"] and not Input.mousetab_prev["Left"] then
			local xmouse = Input.mousetab["X"]
			local ymouse = Input.mousetab["Y"] + GraphicConstants.UP_GAP
			Input.check(xmouse, ymouse)
		end
		Input.mousetab_prev = Input.mousetab

		local joypadButtons = joypad.get()
		-- "Options.CONTROLS["Cycle view"]" pressed
		if joypadButtons[Options.CONTROLS["Cycle view"]] and Input.joypad[Options.CONTROLS["Cycle view"]] ~= joypadButtons[Options.CONTROLS["Cycle view"]] then
			if Tracker.Data.inBattle == 1 then
				Tracker.Data.selectedPlayer = (Tracker.Data.selectedPlayer % 2) + 1
				if Tracker.Data.selectedPlayer == 1 then
					Tracker.Data.selectedSlot = 1
					Tracker.Data.targetPlayer = 2
					Tracker.Data.targetSlot = Memory.readbyte(GameSettings.gBattlerPartyIndexesEnemySlotOne) + 1
				elseif Tracker.Data.selectedPlayer == 2 then
					local enemySlotOne = Memory.readbyte(GameSettings.gBattlerPartyIndexesEnemySlotOne) + 1
					Tracker.Data.selectedSlot = enemySlotOne
					Tracker.Data.targetPlayer = 1
					Tracker.Data.targetSlot = Memory.readbyte(GameSettings.gBattlerPartyIndexesSelfSlotOne) + 1
				end
			end

			Tracker.redraw = true
		end

		-- "Options.CONTROLS["Cycle stat"]" pressed, display box over next stat
		if joypadButtons[Options.CONTROLS["Cycle stat"]] and Input.joypad[Options.CONTROLS["Cycle stat"]] ~= joypadButtons[Options.CONTROLS["Cycle stat"]] then
			Tracker.controller.statIndex = (Tracker.controller.statIndex % 6) + 1
			Tracker.controller.framesSinceInput = 0
			Tracker.redraw = true
		else
			if Tracker.controller.framesSinceInput == Tracker.controller.boxVisibleFrames - 1 then
				Tracker.redraw = true
			end
			if Tracker.controller.framesSinceInput < Tracker.controller.boxVisibleFrames then
				Tracker.controller.framesSinceInput = Tracker.controller.framesSinceInput + 1
			end
		end

		-- "Options.CONTROLS["Next seed"]"
		local allPressed = true
		for button in string.gmatch(Options.CONTROLS["Next seed"], '([^,]+)') do
			if joypadButtons[button] ~= true then
				allPressed = false
			end
		end
		if allPressed == true then
			Main.LoadNextSeed = true
		end

		-- "Options.CONTROLS["Cycle prediction"]" pressed, cycle stat prediction for selected stat
		if joypadButtons[Options.CONTROLS["Cycle prediction"]] and Input.joypad[Options.CONTROLS["Cycle prediction"]] ~= joypadButtons[Options.CONTROLS["Cycle prediction"]] then
			if Tracker.controller.framesSinceInput < Tracker.controller.boxVisibleFrames then
				if Tracker.controller.statIndex == 1 then
					Program.StatButtonState.hp = ((Program.StatButtonState.hp + 1) % 3) + 1
					Buttons[Tracker.controller.statIndex].text = StatButtonStates[Program.StatButtonState.hp]
					Buttons[Tracker.controller.statIndex].textcolor = StatButtonColors[Program.StatButtonState.hp]
					Tracker.controller.framesSinceInput = 0
				elseif Tracker.controller.statIndex == 2 then
					Program.StatButtonState.att = ((Program.StatButtonState.att + 1) % 3) + 1
					Buttons[Tracker.controller.statIndex].text = StatButtonStates[Program.StatButtonState.att]
					Buttons[Tracker.controller.statIndex].textcolor = StatButtonColors[Program.StatButtonState.att]
					Tracker.controller.framesSinceInput = 0
				elseif Tracker.controller.statIndex == 3 then
					Program.StatButtonState.def = ((Program.StatButtonState.def + 1) % 3) + 1
					Buttons[Tracker.controller.statIndex].text = StatButtonStates[Program.StatButtonState.def]
					Buttons[Tracker.controller.statIndex].textcolor = StatButtonColors[Program.StatButtonState.def]
					Tracker.controller.framesSinceInput = 0
				elseif Tracker.controller.statIndex == 4 then
					Program.StatButtonState.spa = ((Program.StatButtonState.spa + 1) % 3) + 1
					Buttons[Tracker.controller.statIndex].text = StatButtonStates[Program.StatButtonState.spa]
					Buttons[Tracker.controller.statIndex].textcolor = StatButtonColors[Program.StatButtonState.spa]
					Tracker.controller.framesSinceInput = 0
				elseif Tracker.controller.statIndex == 5 then
					Program.StatButtonState.spd = ((Program.StatButtonState.spd + 1) % 3) + 1
					Buttons[Tracker.controller.statIndex].text = StatButtonStates[Program.StatButtonState.spd]
					Buttons[Tracker.controller.statIndex].textcolor = StatButtonColors[Program.StatButtonState.spd]
					Tracker.controller.framesSinceInput = 0
				elseif Tracker.controller.statIndex == 6 then
					Program.StatButtonState.spe = ((Program.StatButtonState.spe + 1) % 3) + 1
					Buttons[Tracker.controller.statIndex].text = StatButtonStates[Program.StatButtonState.spe]
					Buttons[Tracker.controller.statIndex].textcolor = StatButtonColors[Program.StatButtonState.spe]
					Tracker.controller.framesSinceInput = 0
				end
				Tracker.TrackStatPrediction(Tracker.Data.selectedPokemon.pokemonID, Program.StatButtonState)
				Tracker.redraw = true
			end
		end

		Input.joypad = joypadButtons
	end
end

function Input.check(xmouse, ymouse)
	-- Tracker input regions
	if Program.state == State.TRACKER then
		---@diagnostic disable-next-line: deprecated
		for i = 1, table.getn(Buttons), 1 do
			if Buttons[i].visible() then
				if Buttons[i].type == ButtonType.singleButton then
					if Input.isInRange(xmouse, ymouse, Buttons[i].box[1], Buttons[i].box[2], Buttons[i].box[3], Buttons[i].box[4]) then
						Buttons[i].onclick()
						Tracker.redraw = true
					end
				end
			end
		end

		--badges
		for index, button in pairs(BadgeButtons.badgeButtons) do
			if button.visible() then
				if Input.isInRange(xmouse, ymouse, button.box[1], button.box[2], button.box[3], button.box[4]) then
					button:onclick()
					Tracker.redraw = true
				end
			end
		end

		-- settings gear
		if Input.isInRange(xmouse, ymouse, GraphicConstants.SCREEN_WIDTH + 101 - 8, 7, 7, 7) then
			Options.redraw = true
			Program.state = State.SETTINGS
		end

		--note box
		if Input.isInRange(xmouse, ymouse, GraphicConstants.SCREEN_WIDTH + 6, 141, GraphicConstants.RIGHT_GAP - 12, 12) and Input.noteForm == nil and Tracker.Data.selectedPlayer == 2 then
			Input.noteForm = forms.newform(290, 60, "Note (70 char. max)", function() Input.noteForm = nil end)
			local textBox = forms.textbox(Input.noteForm, Tracker.GetNote(), 200, 20)
			forms.button(Input.noteForm, "Set", function()
				Tracker.SetNote(forms.gettext(textBox))
				Tracker.redraw = true
				forms.destroy(Input.noteForm)
				Input.noteForm = nil
			end, 200, 0)
		end

		-- Settings menu mouse input regions
	elseif Program.state == State.SETTINGS then
		-- Check for input on any of the option buttons
		for _, button in pairs(Options.optionsButtons) do
			if Input.isInRange(xmouse, ymouse, button.box[1], button.box[2], GraphicConstants.RIGHT_GAP - (button.box[3] * 2), button.box[4]) then
				button.onClick()
			end
		end

		-- Check for input on 'Roms Folder', 'Customize Theme', and 'Close' buttons
		if Input.isInRange(xmouse, ymouse, Options.romsFolderOption.box[1], Options.romsFolderOption.box[2], GraphicConstants.RIGHT_GAP - (Options.romsFolderOption.box[3] * 2), Options.romsFolderOption.box[4]) then
			Options.romsFolderOption.onClick()
		end
		if Input.isInRange(xmouse, ymouse, Options.themeButton.box[1], Options.themeButton.box[2], Options.themeButton.box[3], Options.themeButton.box[4]) then
			Options.themeButton.onClick()
		end
		if Input.isInRange(xmouse, ymouse, Options.closeButton.box[1], Options.closeButton.box[2], Options.closeButton.box[3], Options.closeButton.box[4]) then
			Options.closeButton.onClick()
		end
	elseif Program.state == State.THEME then
		-- Check for input on 'Import', 'Export', and 'Presets' buttons
		if Input.isInRange(xmouse, ymouse, Theme.importThemeButton.box[1], Theme.importThemeButton.box[2], Theme.importThemeButton.box[3], Theme.importThemeButton.box[4]) then
			Theme.importThemeButton.onClick()
		end
		if Input.isInRange(xmouse, ymouse, Theme.exportThemeButton.box[1], Theme.exportThemeButton.box[2], Theme.exportThemeButton.box[3], Theme.exportThemeButton.box[4]) then
			Theme.exportThemeButton.onClick()
		end
		if Input.isInRange(xmouse, ymouse, Theme.presetsButton.box[1], Theme.presetsButton.box[2], Theme.presetsButton.box[3], Theme.presetsButton.box[4]) then
			Theme.presetsButton.onClick()
		end

		-- Check for input on any of the theme config buttons
		for _, button in pairs(Theme.themeButtons) do
			if Input.isInRange(xmouse, ymouse, button.box[1], button.box[2], GraphicConstants.RIGHT_GAP - (button.box[3] * 2), button.box[4]) then
				button.onClick()
			end
		end
		if Input.isInRange(xmouse, ymouse, Theme.moveTypeEnableButton.box[1], Theme.moveTypeEnableButton.box[2], GraphicConstants.RIGHT_GAP - (Theme.moveTypeEnableButton.box[3] * 2), Theme.moveTypeEnableButton.box[4]) then
			Theme.moveTypeEnableButton.onClick()
		end

		-- Check for input on 'Restore Defaults' and 'Close' buttons
		if Input.isInRange(xmouse, ymouse, Theme.restoreDefaultsButton.box[1], Theme.restoreDefaultsButton.box[2], Theme.restoreDefaultsButton.box[3], Theme.restoreDefaultsButton.box[4]) then
			Theme.restoreDefaultsButton.onClick()
		end
		if Input.isInRange(xmouse, ymouse, Theme.closeButton.box[1], Theme.closeButton.box[2], Theme.closeButton.box[3], Theme.closeButton.box[4]) then
			Theme.closeButton.onClick()
		end
	end
end

--[[
	Checks if a mouse click is within a range and returning true.

	xmouse, ymouse: number -> coordinates of the mouse
	x, y: number -> starting coordinate of the region being tested for clicks
	xregion, yregion -> size of the region being tested from the starting coordinates
]]
function Input.isInRange(xmouse, ymouse, x, y, xregion, yregion)
	if xmouse >= x and xmouse <= x + xregion then
		if ymouse >= y and ymouse <= y + yregion then
			return true
		end
	end
	return false
end
