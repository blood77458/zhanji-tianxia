require "canon.data.DataManager"
require "canon.data.MetaManager"


--[[

计算背包空间：
  1、在Shark测试管理工具中，sharkUser里有个boughtGridNum，这是用户购买的空间；
  2、在配置管理工具中，user-level.xml里有每个级别对应的gridNum，这是固有的背包空间；
  3、在配置管理工具中，vip-setting.xml里有每个VIP级别对应的extraInventorySlots，这是VIP用户附加的背包空间

计算已用的空间：
  在wiki中可以查Shark的资源类型，有3个资源类型和1个vip项会占用背包空间
  1、卡牌(资源类型5)，每个占用1格的背包空间，只有cardId不等于additionalCardIds与mainCardId的才在背包中
  2、装备(资源类型6)，每个占用1格的背包空间，属性cardId为0表示在背包中，属性cardId非0表示不在背包中，只统计属性cardId为0的
  3、道具(资源类型7)，这种类型的资源在背包中能叠加，因此要将每个道具的属性amount除以最大叠加数，并向上取整，就能得到这个道具占用的空间，最大叠加数可从game-setting.xml的inventoryMaxStack中读取，有时为99
  4、在Shark测试管理工具中，sharkUserExtend中有个vipPackages，里面包含若干项，每1项占用空间1
  把以上4种的数量加在一起，就得到了已占用的背包空间


]]



BagCalcInfo = class()  

function BagCalcInfo:ctor()
  
end


function BagCalcInfo:create()
  local s = BagCalcInfo.new()
  return s
end


function BagCalcInfo:Calc_Bags_Space( CallbackFunc )  --计算完后调用回调函数 CallbackFunc( Total, Used )
  
  if CallbackFunc ~= nil then --增加回调，因为各个功能会用这个接口
    self.CallbackFunc = CallbackFunc
  end
  
  self:Calc_Step_1()
  
end


function BagCalcInfo:Calc_Step_1()
  
  function Get_Used_Of_7()
      --local GameMetaData = table.deserialize(HeMemDataHolder:getString("GameMeta"))
	  local GameMetaData = MetaManager.game_meta
      local inventoryMaxStack = GameMetaData.gameSettingConfig.inventoryMaxStack--gamesetting中的第8项对应于inventoryMaxStack
      local Total_Used = 0
      for _, aConfig in ipairs( DataManager.getPropsData() ) do  --显示信息
        local This_Used = math.ceil( (aConfig.amount+0) / (inventoryMaxStack+0) )
        Total_Used = Total_Used + This_Used
      end
      self.Total_Used_Of_7 = Total_Used
      
      Get_Used_Of_6()
  
  end

  
  function Get_Used_Of_6()
    
      self.Total_Used_Of_6 = 0
      for _, aConfig in ipairs( DataManager.getEquipsData() ) do
        
        if aConfig.cardId+0 == 0 then  --判断cardId等于0
          
          self.Total_Used_Of_6 =  self.Total_Used_Of_6 + 1
          
        end
        
      end
      
      Get_Used_Of_5()
    
  end
  
  
  function Get_Used_Of_5()
    --这里没有用Request，因为数据已存放于DataManager.GameInitData中
    
    local additionalCardIdsList = DataManager.getGameInitData().sharkUser.additionalCardIds:split(",")
    local mainCardId = DataManager.getGameInitData().sharkUser.mainCardId
    
    self.Total_Used_Of_5 = 0
    for _, aConfig in ipairs( DataManager.getGameInitData().sharkCards.sharkCards) do
      
      if aConfig.cardId+0 ~= mainCardId+0 then  --判断不等于mainCardId 
        
        local GoodState = true
        for _, aAdditionalCardId in ipairs(additionalCardIdsList) do  --判断不等于additionalCardIds
          if aConfig.cardId+0 == aAdditionalCardId+0 then
            GoodState = false
          end
        end
        if GoodState == true then
          self.Total_Used_Of_5 = self.Total_Used_Of_5 + 1
        end
        
      end
      
    end
    
    Get_Used_Of_vipPackages()
    
  end
  
  
  function Get_Used_Of_vipPackages()
    
    if DataManager.getGameInitData().sharkUserExtend ~= nil then
      if DataManager.getGameInitData().sharkUserExtend.vipPackages ~= nil then
        
        self.Total_Used_Of_vipPackages = 0
        for _, aConfig in ipairs( DataManager.getGameInitData().sharkUserExtend.vipPackages ) do
          self.Total_Used_Of_vipPackages = self.Total_Used_Of_vipPackages + 1
        end
        
      else
        self.Total_Used_Of_vipPackages = 0
      end
    else
      self.Total_Used_Of_vipPackages = 0
    end
    
    Finally()
    
  end
  
  
  function Finally()
    
    self.Used_Bags_Space = self.Total_Used_Of_5 + self.Total_Used_Of_6 + self.Total_Used_Of_7 + self.Total_Used_Of_vipPackages
                                    --得到最终结果前，有通信，因此要等待通信的延时
                                    
    print( string.format("Total_Used_Of_5: %d", self.Total_Used_Of_5) )
    print( string.format("Total_Used_Of_6: %d", self.Total_Used_Of_6) )
    print( string.format("Total_Used_Of_7: %d", self.Total_Used_Of_7) )
    print( string.format("Total_Used_Of_vipPackages: %d", self.Total_Used_Of_vipPackages) )
                                    
    self:Calc_Step_2()
    
  end
  
  
  self.Total_Used_Of_5 = nil
  self.Total_Used_Of_6 = nil
  self.Total_Used_Of_7 = nil
  self.Total_Used_Of_vipPackages = nil
  
  Get_Used_Of_7()  --这里调用7，7运行完后自动调用6，6运行完后自动调用5，5运行完后自动调用vipPackages，最后运行Finally()
  
  
end


function BagCalcInfo:Calc_Step_2()
  
  if DataManager.getGameInitData().sharkUserExtend ~= nil then
    self.boughtGridNum = DataManager.getGameInitData().sharkUserExtend.boughtGridNum+0
  else
    self.boughtGridNum = 0
  end
  
  local level = DataManager.getGameInitData().sharkUser.level
  local vipLevel = DataManager.getGameInitData().sharkUser.vipLevel
  
  self.gridNum = 0
  for _, aConfig in ipairs( MetaManager.user_level ) do
    if aConfig.level+0 == level+0 then
      self.gridNum = aConfig.gridNum+0
      break
    end
  end
  
  self.extraInventorySlots = 0
  for _, aConfig in ipairs( MetaManager.vip_setting ) do
    if aConfig.level+0 == vipLevel+0 then
      self.extraInventorySlots = aConfig.extraInventorySlots+0
      break
    end
  end
  

  self.Total_Bags_Space = self.boughtGridNum + self.gridNum + self.extraInventorySlots
  print( string.format("boughtGridNum: %d", self.boughtGridNum) )
  print( string.format("gridNum: %d", self.gridNum) )
  print( string.format("extraInventorySlots: %d", self.extraInventorySlots) )
  
  
  if self.CallbackFunc ~= nil then
      
    print( string.format("Used_Bags_Space: %d", self.Used_Bags_Space) )
    print( string.format("Total_Bags_Space: %d", self.Total_Bags_Space) )
      
    self.CallbackFunc( self.Total_Bags_Space, self.Used_Bags_Space )  --全部计算完后，调用回调函数
      
  end
  
end


function BagCalcInfo:Get_additionalCardIds_Array()
  
end







