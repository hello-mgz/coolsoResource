---glsl
local vsh = [[
	attribute vec2 aPosition;
	attribute vec2 aTexCoord;

    varying vec2 vTexCoord;

    uniform vec4 uColor;
    void main() {
        vTexCoord = vec2(aTexCoord.x, 1.0 - aTexCoord.y);
        gl_Position = vec4(aPosition, 0.0, 1.0);
    }
]]
local fsh = [[
	precision mediump float;

    varying vec2 vTexCoord;

    uniform sampler2D bgImage;
    uniform vec4 uColor;
    uniform vec2 uBgSize;
    uniform float uTime;

    void main() {
        gl_FragColor = texture2D(bgImage, vTexCoord);
    }
]]
local program
local aPositionLoc = 0
local aTexCoordLoc = 1
local fullScreenVbo = 0
local texCoordVbo = 0
local bgWidth = 0
local bgHeight = 0

local csArray
local texId = {}
local number = 150
-- to do 为什么锁屏会重新调用这个方法
function onInit()
	program = cs.Program()
	program:bindAttribute("aPosition", aPositionLoc)
	program:bindAttribute("aTexCoordLoc", aTexCoordLoc)
	--program:bindAttribute("aTexCoord", aTexCoordLoc)
	local result = program:initShaders(vsh, fsh)
	if not result then
		CS_LOG_ERROR("compile error!")
	end
	program:bind()
	program:senduniformf("uColor", 1.0, 1.0, 0.5, 1.0)
	program:senduniformi("bgImage", 0)

	local tempArray = {
		-1, -1,
		-1, 1,
		1, -1,
		1, 1
	}
	csArray = cs.FloatArray()
	csArray:alloc(#tempArray)
	csArray:copy(#tempArray, tempArray)

	tempArray = {
		0, 0,
		0, 1,
		1, 0,
		1, 1
	}
	uvArray = cs.FloatArray()
	uvArray:alloc(#tempArray)
	uvArray:copy(#tempArray, tempArray)

	local vbos = {0, 0}
	glGenBuffers(2, vbos)
	fullScreenVbo = vbos[1]
	glBindBuffer(GL_ARRAY_BUFFER, fullScreenVbo);
	glBufferData(GL_ARRAY_BUFFER, csArray:size(), csArray:data(), GL_STATIC_DRAW)
	texCoordVbo = vbos[2]
	glBindBuffer(GL_ARRAY_BUFFER, texCoordVbo);
	glBufferData(GL_ARRAY_BUFFER, uvArray:size(), uvArray:data(), GL_STATIC_DRAW)

	glBindBuffer(GL_ARRAY_BUFFER, 0);

	for i=0,number-1,1 do
		texId[i] = 0
	end

	CS_LOG_INFO("onInit")
end

function onResize(w,h)
	program:bind()
	program:senduniformf("uBgSize", 1.0, h/w)
	bgWidth = w
	bgHeight = h
	local tempProgram = cs.Program() -- to do 内存泄露
	CS_LOG_INFO("onResize".." w:"..w.." h:"..h)
end

local mTime
local index = 0
function updateTime(time)
	mTime = time
	index = math.floor(mTime*20)%number
end

function onRender()
	if texId[index]==0 then
		local fileName = string.format("luaEffect/bg/bg (%d).jpg", number-index)
		texId[index] = this:loadTextureByFile(fileName)
	end
	glEnable(GL_BLEND)
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)

	program:bind()
	program:senduniformf("uTime", mTime)

	glActiveTexture(GL_TEXTURE0)
	glBindTexture(GL_TEXTURE_2D, texId[index])

	glBindBuffer(GL_ARRAY_BUFFER, fullScreenVbo);
	glVertexAttribPointer(aPositionLoc, 2, GL_FLOAT, GL_FALSE, 0, nil);
	glEnableVertexAttribArray(aPositionLoc)

	glBindBuffer(GL_ARRAY_BUFFER, texCoordVbo);
	glVertexAttribPointer(aTexCoordLoc, 2, GL_FLOAT, GL_FALSE, 0, nil);
	glEnableVertexAttribArray(aTexCoordLoc)

	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	glDisable(GL_BLEND);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

end

function onRelease()
	glDeleteBuffers(2, {fullScreenVbo, texCoordVbo})
	for i=0,number-1,1 do
		glDeleteTextures(1, {texId[i]})
	end
	CS_LOG_INFO("onRelease")
end


