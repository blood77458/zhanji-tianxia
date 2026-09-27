require "hecore.display.CocosObject"
require "canon.models.CountryManager"

--
-- TMXTiledMap
--

TMXTiledMap = class(CocosObject)

function TMXTiledMap:create(aMapFileName)
  if not aMapFileName then 
    print("build TMXTiledMap fail. no filename") 
    return
  end
  local aCocosTiledMap = CCTMXTiledMap:create(aMapFileName)
  return TMXTiledMap.new(aCocosTiledMap)
end

function TMXTiledMap:ctor(aTiledMap)
  --TMXTiledMap.super.ctor(self, aTiledMap)
  
	for i = 1, self.refCocosObj:getChildrenCount() do
		local aBatchChild = tolua.cast(self.refCocosObj:getChildren():objectAtIndex(i - 1), "CCSpriteBatchNode")
		aBatchChild:getTexture():setAliasTexParameters()
	end
	self.tileSize = self.refCocosObj:getTileSize()
	--print(string.format("tileSize:%f, %f", self.tileSize.width, self.tileSize.height))
	self.mapSize = self.refCocosObj:getMapSize()
	--print(string.format("mapSize:%f, %f", self.mapSize.width, self.mapSize.height))
  self.touchEnabled = false
end

function TMXTiledMap:layerNamed( aName )
	return self.refCocosObj:layerNamed(aName)
end

function TMXTiledMap:propertiesForGID( aGID )
	return self.refCocosObj:propertiesForGID(aGID)
end

function TMXTiledMap:getStartPointCoordinate(  )
	local aObject = self.refCocosObj:objectGroupNamed("object")
	local aStartPoint = aObject:objectNamed("startPoint")
	local result = ccp(0 ,0)
	result.x = (tolua.cast(aStartPoint:objectForKey("xCor"), "CCString")):intValue()
	result.y = (tolua.cast(aStartPoint:objectForKey("yCor"), "CCString")):intValue()
	return result
end

function TMXTiledMap:getFirstGIDForEventSource()
  local aEventLayer = self:layerNamed("event")
  local aStartPointGID = aEventLayer:tileGIDAt(self:getStartPointCoordinate())
  return aStartPointGID - 6
end

function TMXTiledMap:eventIDAtTileCoordinate(aCoordinate)
  local aEventLayer = self:layerNamed("event")
  local aTileGID = aEventLayer:tileGIDAt(aCoordinate)
  local aProperties = self:propertiesForGID(aTileGID)
  if aProperties then
    return (tolua.cast(aProperties:objectForKey("event"), "CCString")):getCString()
  end
end

function TMXTiledMap:removeTileInEventLayer(aLocation)
  local aEventLayer = self:layerNamed("event")
  aEventLayer:removeTileAt(aLocation)
end
