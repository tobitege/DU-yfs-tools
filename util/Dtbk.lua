-- Dtbk by Jeronimo
Dtbk = {}
Dtbk.__index = Dtbk;
function Dtbk.new(bank)
    local self = setmetatable({}, Dtbk)
    self.DB = bank
    self.concat = table.concat
    return self
end
function Dtbk.hasKey(self,tag)
    return self.DB.hasKey(tag)
end
function Dtbk.getString(self,tag)
    return self.DB.getStringValue(tag)
end
function Dtbk.setString(self,tag,value)
    self.DB.setStringValue(tag,value)
end
function Dtbk.setData(self,tag,value)
    local str = json.encode(value)
    self.DB.setStringValue(tag,str)
end
function Dtbk.getData(self,tag)
    local tmp = self.DB.getStringValue(tag)
    if tmp == nil then return nil end
    local str = json.decode(tmp)
    return str
end
function Dtbk.remove(self,key)
    self.DB.clearValue(key)
end
function Dtbk.ResetAll(self)
    self.DB.clear()
end
