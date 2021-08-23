function love.conf(t)

	t.identity = "Nightsark"
	t.window.title = "Nightsark"
	t.window.borderless = true
	t.window.vsync = 0
	t.window.resizable = true
	t.externalstorage = true
	t.window.msaa = 128
	t.window.highdpi = true
	t.accelerometerjoystick = false
	
	t.modules.physics = false
	t.modules.joystick = false
	t.modules.video = false

end
