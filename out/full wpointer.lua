package.preload['YFS-Tools:../util/wpointer/wpointer0.lua']=(function()
function LinkedList(name, prefix)
    local functions = {}
    local internalDataTable = {}
    local internalTableSize = 0
    local removeKey,addKey,indexKey,refKey = prefix .. 'Remove',prefix .. 'Add',prefix..'index',prefix..'ref'

    functions[removeKey] = function (node)
        local tblSize,internalDataTable = internalTableSize,internalDataTable
        if tblSize > 1 then
            if node[indexKey] == -1 then return end
            local lastElement,replaceNodeIndex = internalDataTable[tblSize],node[indexKey]
            internalDataTable[replaceNodeIndex] = lastElement
            internalDataTable[tblSize] = nil
            lastElement[indexKey] = replaceNodeIndex
            internalTableSize = tblSize - 1
            node[indexKey] = -1
            node[refKey] = nil
        elseif tblSize == 1 then
            internalDataTable[1] = nil
            internalTableSize = 0
            node[indexKey] = -1
            node[refKey] = nil
        end
    end

    functions[addKey] = function (node, override)
        local indexKey,refKey = indexKey,refKey
        if node[indexKey] and node[indexKey] ~= -1 then
            if not node[refKey] == functions or override then
                node[refKey][removeKey](node)
            else
                return
            end
        end
        local tblSize = internalTableSize + 1
        internalDataTable[tblSize] = node
        node[indexKey] = tblSize
        node[refKey] = functions
        internalTableSize = tblSize
    end

    functions[prefix .. 'GetData'] = function ()
        return internalDataTable, internalTableSize
    end

    return functions
end

local math = math
local sin, cos, rad, type = math.sin,math.cos,math.rad, type

function RotMatrixToQuat(m1,m2,m3)
    local m11,m22,m33 = m1[1],m2[2],m3[3]
    local t=m11+m22+m33
    if t>0 then
        local s=0.5/(t+1)^(0.5)
        return (m2[3]-m3[2])*s,(m3[1]-m1[3])*s,(m1[2]-m2[1])*s,0.25/s
    elseif m11>m22 and m11>m33 then
        local s = 1/(2*(1+m11-m22-m33)^(0.5))
        return 0.25/s,(m2[1]+m1[2])*s,(m3[1]+m1[3])*s,(m2[3]-m3[2])*s
    elseif m22>m33 then
        local s=1/(2*(1+m22-m11-m33)^(0.5))
        return (m2[1]+m1[2])*s,0.25/s,(m3[2]+m2[3])*s,(m3[1]-m1[3])*s
    else
        local s=1/(2*(1+m33-m11-m22)^(0.5))
        return (m3[1]+m1[3])*s,(m3[2]+m2[3])*s,0.25/s,(m1[2]-m2[1])*s
    end
end

function GetQuaternion(x,y,z,w)
    if type(x) == 'number' then
        if w == nil then
            if x == x and y == y and z == z then
                local rad,sin,cos = rad,sin,cos
                x,y,z = -rad(x * 0.5),rad(y * 0.5),-rad(z * 0.5)
                local sP,sH,sR=sin(x),sin(y),sin(z)
                local cP,cH,cR=cos(x),cos(y),cos(z)
                return (sP*cH*cR-cP*sH*sR),(cP*sH*cR+sP*cH*sR),(cP*cH*sR-sP*sH*cR),(cP*cH*cR+sP*sH*sR)
            else
                return 0,0,0,1
            end
        else
            return x,y,z,w
        end
    elseif type(x) == 'table' then
        if #x == 3 then
            local x,y,z,w = RotMatrixToQuat(x, y, z)
            return x,y,z,-w
        elseif #x == 4 then
            return x[1],x[2],x[3],x[4]
        else
            print('Unsupported Rotation!')
        end
    end
end
function QuaternionMultiply(ax,ay,az,aw,bx,by,bz,bw)
    return ax*bw+aw*bx+ay*bz-az*by,
    ay*bw+aw*by+az*bx-ax*bz,
    az*bw+aw*bz+ax*by-ay*bx,
    aw*bw-ax*bx-ay*by-az*bz
end

function RotatePoint(ax,ay,az,aw,oX,oY,oZ,wX,wY,wZ)
    local t1,t2,t3 = 2*(ax*oY - ay*oX),2*(ax*oZ - az*oX),2*(ay*oZ - az*oY)
    return 
    oX + ay*t1 + az*t2 + aw*t3 + wX,
    oY - ax*t1 - aw*t2 + az*t3 + wY,
    oZ + aw*t1 - ax*t2 - ay*t3 + wZ
end

function GetRotationManager(out_rotation, wXYZ, name)
    --====================--
    --Local Math Functions--
    --====================--
    local print,type,unpack,multiply,rotatePoint,getQuaternion = DUSystem.print,type,table.unpack,QuaternionMultiply,RotatePoint,GetQuaternion

    local superManager,needsUpdate,notForwarded,needNormal = nil,false,true,false
    local outBubble = nil
    --=================--
    --Positional Values--
    --=================--
    local pX,pY,pZ = wXYZ[1],wXYZ[2],wXYZ[3] -- These are original values, for relative to super rotation
    local positionIsRelative = false
    local doRotateOri,doRotatePos = true,true
    local posY = math.random()*0.00001

    --==================--
    --Orientation Values--
    --==================--
    local tix,tiy,tiz,tiw = 0,0,0,1 -- temp intermediate rotation values

    local ix,iy,iz,iw = 0,0,0,1 -- intermediate rotation values
    local nx,ny,nz = 0,1,0

    local subRotQueue = {}
    local subRotations = LinkedList(name, 'sub')

    --==============--
    --Function Array--
    --==============--
    local out = {}

    --=======--
    --=Cache=--
    --=======--
    local cache = {0,0,0,1,0,0,0,0,0,0}

    --============================--
    --Primary Processing Functions--
    --============================--
    local function process(wx,wy,wz,ww,lX,lY,lZ,lTX,lTY,lTZ)
        if not wx then
            wx,wy,wz,ww,lX,lY,lZ,lTX,lTY,lTZ = unpack(cache)
        else
            cache = {wx,wy,wz,ww,lX,lY,lZ,lTX,lTY,lTZ}
        end
        local dx,dy,dz = pX,pY,pZ
        if not positionIsRelative then
            dx,dy,dz = dx - lX, dy - lY, dz - lZ
        end
        if doRotatePos then
            wXYZ[1],wXYZ[2],wXYZ[3] = rotatePoint(wx,wy,wz,-ww,dx,dy,dz,lTX,lTY,lTZ)
        else
            wXYZ[1],wXYZ[2],wXYZ[3] = dx+lTX,dy+lTY,dz+lTZ
        end

        ix = ix or 1
        iy = iy or 1
        iz = iz or 1
        iw = iw or 1
        if doRotateOri then
            wx,wy,wz,ww = multiply(ix or 1,iy or 1,iz or 1,iw,wx,wy,wz,ww)
        else
            wx,wy,wz,ww = ix,iy,iz,iw
        end

        out_rotation[1],out_rotation[2],out_rotation[3],out_rotation[4] = wx,wy,wz,ww
        if needNormal then
            nx,ny,nz = 2*(wx*wy+wz*ww),1-2*(wx*wx+wz*wz),2*(wy*wz-wx*ww)
        end
        local subRots,subRotsSize = subRotations.subGetData()

        for i=1, subRotsSize do
            subRots[i].update(wx,wy,wz,ww,pX,pY,pZ,wXYZ[1],wXYZ[2],wXYZ[3])
        end
        needsUpdate = false
        notForwarded = true
    end
    out.update = process
    local function validate()
        if not superManager then
            process()
        else
            superManager.bubble()
        end
    end
    local function rotate()
        local tx,ty,tz,tw = getQuaternion(tix,tiy,tiz,tiw)
        if tx ~= ix or ty~= iy or tz ~= iz or tw ~= iw then
            ix, iy, iz, iw = tx, ty, tz, tw
            validate()
            out.bubble()
            return true
        end
        return false
    end
    function out.enableNormal()
        needNormal = true
    end
    function out.disableNormal()
        needNormal = false
    end
    function out.setSuperManager(rotManager)
        superManager = rotManager
        if not rotManager then
            cache = {0,0,0,1,0,0,0,0,0,0}
            needsUpdate = true
        end
    end
    function out.addToQueue(func)
        if not needsUpdate then
            subRotQueue[#subRotQueue+1] = func
        end
    end

    function out.addSubRotation(rotManager)
        rotManager.setSuperManager(out)
        subRotations.subAdd(rotManager, true)
        out.bubble()
    end
    function out.remove()
        if superManager then
            superManager.removeSubRotation(out)
            out.setSuperManager(false)
            out.bubble()
        end
    end
    function out.removeSubRotation(sub)
        sub.setSuperManager(false)
        subRotations.subRemove(sub)
    end
    function out.bubble()
        if superManager and not needsUpdate then
            subRotQueue = {}
            needsUpdate = true
            notForwarded = false
            superManager.addToQueue(process)
        else
            needsUpdate = true
        end
    end

    function out.checkUpdate()
        local neededUpdate = needsUpdate
        if neededUpdate and notForwarded then
            process()
            subRotQueue = {}
        elseif notForwarded then
            for i=1, #subRotQueue do
                subRotQueue[i]()
            end
            subRotQueue = {}
        elseif superManager then
            superManager.checkUpdate()
        end
        return neededUpdate
    end
    local outBubble = out.bubble
    local function assignFunctions(inFuncArr,specialCall)
        inFuncArr.update = process
        function inFuncArr.getPosition() return pX,pY,pZ end
        function inFuncArr.getRotationManger() return out end
        function inFuncArr.getSubRotationData() return subRotations.subGetData() end
        inFuncArr.checkUpdate = out.checkUpdate
        function inFuncArr.setPosition(tx,ty,tz)
            if type(tx) == 'table' then
                tx,ty,tz = tx[1],tx[2],tx[3]
            end
            if not (tx ~= tx or ty ~= ty or tz ~= tz)  then
                local tmpY = (ty or 0)+posY
                if pX ~= tx or pY ~= tmpY or pZ ~= tz then
                    pX,pY,pZ = tx,tmpY,tz
                    outBubble()
                    return true
                end
            end
            return false
        end
        function inFuncArr.getNormal()
            return nx,ny,nz
        end
        function inFuncArr.rotateXYZ(rotX,rotY,rotZ,rotW)
            if rotX and rotY and rotZ then
                tix,tiy,tiz,tiw = rotX,rotY,rotZ,rotW
                rotate()
                if specialCall then specialCall() end
            else
                if type(rotX) == 'table' then
                    if #rotX == 3 then
                        ---@diagnostic disable-next-line: cast-local-type
                        tix,tiy,tiz,tiw = rotX[1],rotX[2],rotX[3],nil
                        local result = rotate()
                        if specialCall then specialCall() end
                        goto valid
                    end
                end
                ---@diagnostic disable-next-line: param-type-mismatch
                system.print('Invalid format. Must be three angles, or right, forward and up vectors, or a quaternion. Use radians if angles.')
                ::valid::
                return false
            end
        end

        ---@diagnostic disable-next-line: cast-local-type
        function inFuncArr.rotateX(rotX) tix = rotX; tiw = nil; rotate(); if specialCall then specialCall() end end
        ---@diagnostic disable-next-line: cast-local-type
        function inFuncArr.rotateY(rotY) tiy = rotY; tiw = nil; rotate(); if specialCall then specialCall() end end
        ---@diagnostic disable-next-line: cast-local-type
        function inFuncArr.rotateZ(rotZ) tiz = rotZ; tiw = nil; rotate(); if specialCall then specialCall() end end

        function inFuncArr.setDoRotateOri(rot) doRotateOri = rot; outBubble() end
        function inFuncArr.setDoRotatePos(rot) doRotatePos = rot; outBubble() end

        function inFuncArr.setPositionIsRelative(isRelative) positionIsRelative = isRelative; outBubble() end
        function inFuncArr.getRotation() return ix, iy, iz, iw end
    end
    out.assignFunctions = assignFunctions

    return out
end
end)
package.preload['YFS-Tools:../util/wpointer/wpointer1.lua']=(function()
function WPointer(x,y,z, radius, name, type, localeType, subId)
    local sqrt,floor,max,round=math.sqrt,math.floor,math.max,Round
    local getCWorldPos,getCMass = construct.getWorldPosition,construct.getMass

    local keyframe = 0
    local self = {
        radius = radius,
        x = x,
        y = y,
        z = z,
        name = name,
        type = type,
        localeType = localeType,
        subId = subId,
        keyframe = keyframe
    }

    function self.getWaypointInfo()
        ---@diagnostic disable-next-line: missing-parameter
        local cid = construct.getId()
        local cPos = getCWorldPos(cid)
        ---@diagnostic disable-next-line: need-check-nil
        local px,py,pz = self.x-cPos[1], self.y-cPos[2], self.z-cPos[3]
        local distance = sqrt(px*px + py*py + pz*pz)
        local warpCost = 0
        -- min 2 SU, max 500 SU (1 SU = 200000 m)
        if distance > 400000 and distance <= 100000000 then
            local tons = getCMass(cid) / 1000
            warpCost = max(floor(tons*floor(((distance/1000)/200))*0.00024), 1)
        end
        local disR = round(distance, 4)
        if DEBUG then P("getWaypointInfo") end
        return self.name, round((distance/1000)/200, 4), warpCost, round((distance/1000), 4), disR
    end

    return self
end
end)
package.preload['YFS-Tools:../util/wpointer/wpointer2.lua']=(function()
PositionTypes = {
    globalP=false,
    localP=true
}
OrientationTypes = {
    globalO=false,
    localO=true 
}
local print = DUSystem.print
function ObjectGroup(objects, transX, transY)
    objects = objects or {}
    local self={style='',gStyle='',class='default', objects=objects,transX=transX,transY=transY,enabled=true,glow=false,gRad=10,scale = false,isZSorting=true}
    function self.addObject(object, id)
        id=id or #objects+1
        objects[id]=object
        return id
    end
    function self.removeObject(id) objects[id] = {} end

    function self.hide() self.enabled = false end
    function self.show() self.enabled = true end
    function self.isEnabled() return self.enabled end
    function self.setZSort(isZSorting) self.isZSorting = isZSorting end

    function self.setClass(class) self.class = class end
    function self.setStyle(style) self.style = style end
    function self.setGlowStyle(gStyle) self.gStyle = gStyle end
    function self.setGlow(enable,radius,scale) self.glow = enable; self.gRad = radius or self.gRad; self.scale = scale or false end 
    return self
end
ConstructReferential = GetRotationManager({0,0,0,1},{0,0,0}, 'Construct')
ConstructReferential.assignFunctions(ConstructReferential)
ConstructOriReferential = GetRotationManager({0,0,0,1},{0,0,0}, 'ConstructOri')
ConstructOriReferential.assignFunctions(ConstructOriReferential)
function Object(posType, oriType)

    local multiGroup,singleGroup,uiGroups={},{},{}
    local positionType=positionType
    local orientationType=orientationType
    local ori = {0,0,0,1}
    local position = {0,0,0}
    local objRotationHandler = GetRotationManager(ori,position, 'Object Rotation Handler')

    local self = {
        true, -- 1
        multiGroup, -- 2
        singleGroup, -- 3
        uiGroups, -- 4
        ori, -- 5
        position, -- 6
        oriType, -- 7
        posType -- 8
    }
    objRotationHandler.assignFunctions(self)
    self.setPositionIsRelative(true)
    self.setPositionIsRelative = nil
    function self.hide() self[1] = false end
    function self.show() self[1] = true end

    local loadUIModule = LoadUIModule
    if loadUIModule == nil then
        --print('No UI Module installed.')
        loadUIModule = function() end
    end
    local loadPureModule = LoadPureModule
    if loadPureModule == nil then
        --print('No Pure Module installed.')
        loadPureModule = function() end
    end

    loadPureModule(self, multiGroup, singleGroup)
    loadUIModule(self, uiGroups, objRotationHandler)
    local function choose()
        objRotationHandler.remove()
        local oriType,posType = self[7],self[8]
        if oriType and posType then
            ConstructReferential.addSubRotation(objRotationHandler)
        elseif oriType then
            ConstructOriReferential.addSubRotation(objRotationHandler)
        end
        self.setDoRotateOri(oriType)
        self.setDoRotatePos(posType)
    end
    choose()
    function self.setOrientationType(orientationType)
        self[7] = orientationType
        choose()
    end
    function self.setPositionType(positionType)
        self[8] = positionType
        choose()
    end
    function self.GetRotationManager()
        return objRotationHandler
    end
    function self.addSubObject(object)
        return objRotationHandler.addSubRotation(object.GetRotationManager())
    end
    function self.removeSubObject(id)
        objRotationHandler.removeSubRotation(id)
    end

    return self
end

function ObjectBuilderLinear()
    local self = {}
    function self.setPositionType(positionType)
        local self = {}
        local positionType = positionType
        function self.setOrientationType(orientationType)
            local self = {}
            local orientationType = orientationType
            function self.build()
                return Object(positionType, orientationType)
            end
            return self
        end
        return self
    end
    return self
end
end)
package.preload['YFS-Tools:../util/wpointer/wpointer3.lua']=(function()
function LoadPureModule(self, singleGroup, multiGroup)
    function self.getMultiPointBuilder(groupId)
        local builder = {}
        local multiplePoints = LinkedList('','')
        multiGroup[#multiGroup+1] = multiplePoints
        function builder.addMultiPointSVG()
            local shown = false
            local pointSetX,pointSetY,pointSetZ={},{},{}
            local mp = {pointSetX,pointSetY,pointSetZ,false,false}
            local self={}
            local pC=1
            function self.show()
                if not shown then
                    shown = true
                    multiplePoints.Add(mp)
                end
            end
            function self.hide()
                if shown then
                    shown = false
                    multiplePoints.Remove(mp)
                end
            end
            function self.addPoint(point)
                pointSetX[pC]=point[1]
                pointSetY[pC]=point[2]
                pointSetZ[pC]=point[3]
                pC=pC+1
                return self
            end
            function self.setPoints(bulk)
                for i=1,#bulk do
                    local point = bulk[i]
                    pointSetX[i]=point[1]
                    pointSetY[i]=point[2]
                    pointSetZ[i]=point[3]
                end
                pC=#bulk+1
                return self
            end
            function self.setDrawFunction(draw)
                mp[4] = draw
                --system.print("getMultiPointBuilder.Draw() set")
                return self
            end
            function self.setData(dat)
                mp[5] = dat
                return self
            end
            function self.build()
                if pC > 1 then
                    multiplePoints.Add(mp)
                    shown = true
                else print("WARNING! Malformed multi-point build operation, no points specified. Ignoring.")
                end
            end
            return self
        end
        return builder
    end

    function self.getSinglePointBuilder(groupId)
        local builder = {}
        local points = LinkedList('','')
        singleGroup[#singleGroup+1] = points
        function builder.addSinglePointSVG()
            local shown = false
            local outArr = {false,false,false,false,false}

            function self.setPosition(px,py,pz)
                if type(px) == 'table' then
                    outArr[1],outArr[2],outArr[3]=px[1],px[2],px[3]
                else
                    outArr[1],outArr[2],outArr[3]=px,py,pz
                end
                return self
            end

            function self.setDrawFunction(draw)
                outArr[4] = draw
                --system.print("getSinglePointBuilder.Draw() set")
                return self
            end

            function self.setData(dat)
                outArr[5] = dat
                return self
            end

            function self.show()
                if not shown then
                    shown = true
                end
            end
            function self.hide()
                if shown then
                    points.Remove(outArr)
                    shown = false
                end
            end
            function self.build()
                points.Add(outArr)
                shown = true
                return self
            end
            return self
        end
        return builder
    end
end

function ProcessPureModule(zBC, singleGroup, multiGroup, zBuffer, zSorter,
        mXX, mXY, mXZ,
        mYX, mYY, mYZ,
        mZX, mZY, mZZ,
        mXW, mYW, mZW)
    for cG = 1, #singleGroup do
        local group = singleGroup[cG]
        local singleGroups,singleSize = group.GetData()
        for sGC = 1, singleSize do
            local singleGroup = singleGroups[sGC]
            local x,y,z = singleGroup[1], singleGroup[2], singleGroup[3]
            local pz = mYX*x + mYY*y + mYZ*z + mYW
            if pz < 0 then goto disabled end
            zBC = zBC + 1
            zSorter[zBC] = -pz
            zBuffer[-pz] = singleGroup[4]((mXX*x + mXY*y + mXZ*z + mXW)/pz,(mZX*x + mZY*y + mZZ*z + mZW)/pz,pz,singleGroup[5])
            ::disabled::
        end
    end
    for cG = 1, #multiGroup do
        local group = multiGroup[cG]
        local multiGroups,groupSize = group.GetData()
        for mGC = 1, groupSize do
            local multiGroup = multiGroups[mGC]

            local tPointsX,tPointsY,tPointsZ = {},{},{}
            local pointsX,pointsY,pointsZ = multiGroup[1],multiGroup[2],multiGroup[3]
            local size = #pointsX
            local mGAvg = 0
            for pC=1,size do
                local x,y,z = pointsX[pC],pointsY[pC],pointsZ[pC]
                local pz = mYX*x + mYY*y + mYZ*z + mYW
                if pz < 0 then
                    goto disabled
                end

                tPointsX[pC],tPointsY[pC] = (mXX*x + mXY*y + mXZ*z + mXW)/pz,(mZX*x + mZY*y + mZZ*z + mZW)/pz
                mGAvg = mGAvg + pz
            end
            local depth = -mGAvg/size
            zBC = zBC + 1
            zSorter[zBC] = depth
            zBuffer[depth] = multiGroup[4](tPointsX,tPointsY,depth,multiGroup[5])
            ::disabled::
        end
    end
    return zBC
end
end)
package.preload['YFS-Tools:../util/wpointer/wpointer4.lua']=(function()
---@diagnostic disable: missing-parameter
function Projector()
    -- Localize frequently accessed data
    local construct, player, system, math = DUConstruct, DUPlayer, DUSystem, math

    -- Internal Parameters
    local frameBuffer,frameRender,isSmooth,lowLatency = {'',''},true,true,true

    -- Localize frequently accessed functions
    --- System-based function calls
    local getWidth, getHeight, getTime, setScreen =
    system.getScreenWidth,
    system.getScreenHeight,
    system.getArkTime,
    system.setScreen

    --- Camera-based function calls
    local getCamWorldRight, getCamWorldFwd, getCamWorldUp, getCamWorldPos =
    system.getCameraWorldRight,
    system.getCameraWorldForward,
    system.getCameraWorldUp,
    system.getCameraWorldPos

    local getConWorldRight, getConWorldFwd, getConWorldUp, getConWorldPos = 
    construct.getWorldRight,
    construct.getWorldForward,
    construct.getWorldUp,
    construct.getWorldPosition

    --- Manager-based function calls
    ---- Quaternion operations
    local rotMatrixToQuat,quatMulti = RotMatrixToQuat,QuaternionMultiply

    -- Localize Math functions
    local tan, atan, rad = math.tan, math.atan, math.rad

    --- FOV Paramters
    local horizontalFov = system.getCameraHorizontalFov
    local fnearDivAspect = 0

    local objectGroups = LinkedList('Group', '')

    local self = {}

    function self.getSize(size, zDepth, max, min)
        local pSize = atan(size, zDepth) * fnearDivAspect
        if max then
            if pSize >= max then
                return max
            else
                if min then
                    if pSize < min then
                        return min
                    end
                end
                return pSize
            end
        end
        return pSize
    end

    function self.refresh() frameRender = not frameRender; end

    function self.setLowLatency(low) lowLatency = low; end

    function self.setSmooth(iss) isSmooth = iss; end

    function self.addObjectGroup(objectGroup) objectGroups.Add(objectGroup) end

    function self.removeObjectGroup(objectGroup) objectGroups.Remove(objectGroup) end

    function self.getSVG()
        local getTime, atan, sort, unpack, format, concat, quatMulti = getTime, atan, table.sort, table.unpack, string.format, table.concat, quatMulti
        local startTime = getTime(self)
        frameRender = not frameRender
        local isClicked = false
        if Clicked then
            Clicked = false
            isClicked = true
        end
        local isHolding = holding

        local buffer = {}

        local width,height = getWidth(), getHeight()
        local aspect = width/height
        local tanFov = tan(rad(horizontalFov() * 0.5))

        --- Matrix Subprocessing
        local nearDivAspect = (width*0.5) / tanFov
        fnearDivAspect = nearDivAspect

        -- Localize projection matrix values
        local px1 = 1 / tanFov
        local pz3 = px1 * aspect

        local pxw,pzw = px1 * width * 0.5, -pz3 * height * 0.5
        -- Localize screen info
        local objectGroupsArray,objectGroupSize = objectGroups.GetData()
        local svgBuffer,svgZBuffer,svgBufferCounter = {},{},0

        local processPure = ProcessPureModule
        local processUI = ProcessUIModule
        local processRots = ProcessOrientations
        local processEvents = ProcessActionEvents
        if processPure == nil then
            processPure = function(zBC) return zBC end
        end
        if processUI == nil then
            processUI = function(zBC) return zBC end
            processRots = function() end
            processEvents = function() end
        end
        local predefinedRotations = {}
        local camR,camF,camU,camP = getCamWorldRight(),getCamWorldFwd(),getCamWorldUp(),getCamWorldPos()
        camR = camR or {1,1,1}
        camF = camF or {1,1,1}
        camU = camU or {1,1,1}
        camP = camP or {1,1,1}
        do
            local cwr,cwf,cwu = getConWorldRight(),getConWorldFwd(),getConWorldUp()
            ConstructReferential.rotateXYZ(cwr,cwf,cwu)
            ConstructOriReferential.rotateXYZ(cwr,cwf,cwu)
            ConstructReferential.setPosition(getConWorldPos())
            ConstructReferential.checkUpdate()
            ConstructOriReferential.checkUpdate()
        end
        local vx,vy,vz,vw = rotMatrixToQuat(camR,camF,camU)

        local vxx,vxy,vxz,vyx,vyy,vyz,vzx,vzy,vzz = camR[1]*pxw,camR[2]*pxw,camR[3]*pxw,camF[1],camF[2],camF[3],camU[1]*pzw,camU[2]*pzw,camU[3]*pzw
        local ex,ey,ez = camP[1],camP[2],camP[3]
        local deltaPreProcessing = getTime() - startTime
        local deltaDrawProcessing, deltaEvent, deltaZSort, deltaZBufferCopy, deltaPostProcessing = 0,0,0,0,0
        P("getSvg "..objectGroupSize)
        for i = 1, objectGroupSize do
            local objectGroup = objectGroupsArray[i]
            if objectGroup.enabled == false then
                goto not_enabled
            end
            local objects = objectGroup.objects

            local avgZ, avgZC = 0, 0
            local zBuffer, zSorter, zBC = {},{}, 0

            local notIntersected = true
            for m = 1, #objects do
                local obj = objects[m]
                if not obj[1] then
                    goto is_nil
                end

                obj.checkUpdate()
                local objOri, objPos, oriType, posType  = obj[5], obj[6], obj[7], obj[8]
                local objX,objY,objZ = objPos[1]-ex,objPos[2]-ey,objPos[3]-ez
                local mx,my,mz,mw = objOri[1], objOri[2], objOri[3], objOri[4]
                local a,b,c,d = quatMulti(mx,my,mz,mw,vx,vy,vz,vw)
                local aa, ab, ac, ad, bb, bc, bd, cc, cd = 2*a*a, 2*a*b, 2*a*c, 2*a*d, 2*b*b, 2*b*c, 2*b*d, 2*c*c, 2*c*d
                local mXX, mXY, mXZ,
                      mYX, mYY, mYZ,
                      mZX, mZY, mZZ = 
                (1 - bb - cc)*pxw,    (ab + cd)*pxw,    (ac - bd)*pxw,
                (ab - cd),           (1 - aa - cc),     (bc + ad),
                (ac + bd)*pzw,        (bc - ad)*pzw,    (1 - aa - bb)*pzw

                local mWX,mWY,mWZ = ((vxx*objX+vxy*objY+vxz*objZ)),(vyx*objX+vyy*objY+vyz*objZ),((vzx*objX+vzy*objY+vzz*objZ))

                local processRotations = processRots(predefinedRotations,vx,vy,vz,vw,pxw,pzw)
                predefinedRotations[mx .. ',' .. my .. ',' .. mz .. ',' .. mw] = {mXX,mXZ,mYX,mYZ,mZX,mZZ}

                avgZ = avgZ + mWY
                local uiGroups = obj[4]

                -- Process Actionables
                local eventStartTime = getTime()
                obj.previousUI = processEvents(uiGroups, obj.previousUI, isClicked, isHolding, vyx, vyy, vyz, processRotations, ex,ey,ez, sort)
                local drawProcessingStartTime = getTime()
                deltaEvent = deltaEvent + drawProcessingStartTime - eventStartTime
                -- Progress Pure

                zBC = processPure(zBC, obj[2], obj[3], zBuffer, zSorter,
                    mXX, mXY, mXZ,
                    mYX, mYY, mYZ,
                    mZX, mZY, mZZ,
                    mWX, mWY, mWZ
                )
                -- Process UI
                zBC = processUI(zBC, uiGroups, zBuffer, zSorter,
                            vxx, vxy, vxz,
                            vyx, vyy, vyz,
                            vzx, vzy, vzz,
                            ex,ey,ez,
                        processRotations,nearDivAspect)
                deltaDrawProcessing = deltaDrawProcessing + getTime() - drawProcessingStartTime
                ::is_nil::
            end
            local zSortingStartTime = getTime()
            if objectGroup.isZSorting then
                sort(zSorter)
            end
            local zBufferCopyStartTime = getTime()
            deltaZSort = deltaZSort + zBufferCopyStartTime - zSortingStartTime
            local drawStringData = {}
            for zC = 1, zBC do
                drawStringData[zC] = zBuffer[zSorter[zC]]
            end
            local postProcessingStartTime = getTime()
            deltaZBufferCopy = deltaZBufferCopy + postProcessingStartTime - zBufferCopyStartTime
            if zBC > 0 then
                local dpth = avgZ / avgZC
                local actualSVGCode = concat(drawStringData)
                local beginning, ending = '', ''
                if isSmooth then
                    ending = '</div>'
                    if frameRender then
                        beginning = '<div class="second" style="visibility: hidden">'
                    else
                        beginning = '<style>.first{animation: f1 0.008s infinite linear;} .second{animation: f2 0.008s infinite linear;} @keyframes f1 {from {visibility: hidden;} to {visibility: hidden;}} @keyframes f2 {from {visibility: visible;} to { visibility: visible;}}</style><div class="first">'
                    end
                end
                local styleHeader = ('<style>svg{background:none;width:%gpx;height:%gpx;position:absolute;top:0px;left:0px;}'):format(width,height)
                local svgHeader = ('<svg viewbox="-%g -%g %g %g"'):format(width*0.5,height*0.5,width,height)

                svgBufferCounter = svgBufferCounter + 1
                svgZBuffer[svgBufferCounter] = dpth

                if objectGroup.glow then
                    local size
                    if objectGroup.scale then
                        size = atan(objectGroup.gRad, dpth) * nearDivAspect
                    else
                        size = objectGroup.gRad
                    end
                    svgBuffer[dpth] = concat({
                                beginning,
                                '<div class="', objectGroup.class ,'">',
                                styleHeader,
                                objectGroup.style,
                                '.blur { filter: blur(',size,'px) brightness(60%) saturate(3);',
                                objectGroup.gStyle, '}</style>',
                                svgHeader,
                                ' class="blur">',
                                actualSVGCode,'</svg>',
                                svgHeader, '>',
                                actualSVGCode,
                                '</svg></div>',
                                ending
                            })
                else
                    svgBuffer[dpth] = concat({
                                beginning,
                                '<div class="', objectGroup.class ,'">',
                                styleHeader,
                                objectGroup.style, '}</style>',
                                svgHeader, '>',
                                actualSVGCode,
                                '</svg></div>',
                                ending
                            })
                end
            end
            deltaPostProcessing = deltaPostProcessing + getTime() - postProcessingStartTime
            ::not_enabled::
        end
        --P("getSvg "..Out.DumpVar(svgZBuffer))

        sort(svgZBuffer)

        for i = 1, svgBufferCounter do
            buffer[i] = svgBuffer[svgZBuffer[i]]
        end

        if frameRender then
            frameBuffer[2] = concat(buffer)
            return concat(frameBuffer), deltaPreProcessing, deltaDrawProcessing, deltaEvent, deltaZSort, deltaZBufferCopy, deltaPostProcessing
        end
        if isSmooth then
            frameBuffer[1] = concat(buffer)
            if lowLatency then
---@diagnostic disable-next-line: param-type-mismatch
                setScreen('<div>Refresh Required</div>') -- magical things happen when doing this for some reason, some really, really weird reason.
            end
        else
            frameBuffer[1] = ''
        end
        return nil
    end

    return self
end
end)
