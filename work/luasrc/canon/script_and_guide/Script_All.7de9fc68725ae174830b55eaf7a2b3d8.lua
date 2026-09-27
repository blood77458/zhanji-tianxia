return function()

require "canon.script_and_guide.Include_Get_Person_Pic"

local dialogFileName = Global_CurrentDialogFile or "event_conversation"
local event_conversation = require ("canon.configs."..dialogFileName)

local card_meta = require "canon.configs.card_meta"

Clicking_Only();
disableUserInteraction();

setIsShowDialogSkipButton(1);

Set_ShareData( "Last_PicId", 0 ); --初始化(不变)

Set_ShareData("Skip_Story", 0)

local DialogIndex = Get_ShareData( "Show_Dialog_Index" );
local activeOpportunity = Get_ShareData( "Show_Dialog_activeOpportunity" );
if DialogIndex == nil or DialogIndex < 0 then
  DialogIndex = -1
end

Set_ShareData( "Previous_Dialog_Content", "" )
Set_ShareData( "Previous_Dialog_Person", "" )
Set_ShareData("Next_Order_Id", -1)
Set_ShareData("Person_Id_Talker_1", -1)
Set_ShareData("Person_Id_Talker_2", -1)
--[[
Set_ShareData("Exit_Type_Talker_1", 0)
Set_ShareData("Exit_Type_Talker_2", 0)
]]
Set_ShareData("Previsou_Talker_Exit_Type", 0)
Set_ShareData("Previsou_Talker_Side", 0)
for _, aConfig in ipairs( event_conversation ) do
  local One_Event = aConfig;
  local next_order_id = Get_ShareData("Next_Order_Id")
  if (One_Event.dialogId == DialogIndex) and (One_Event.activeOpportunity == activeOpportunity) and ((next_order_id == -1) and true or (next_order_id == One_Event.dialogOrderId)) then  --对话n
    local ShowText = Localization:getInstance():getText( One_Event.dialogContent, {player = DataManager.getCurrUser().nickName} )
    if One_Event.figureId==nil then print("配置不正确，figureId为空") end
    --print( "Begin: " .. One_Event.dialogContent )
    Set_ShareData("Next_Order_Id", One_Event.nextDialogID)
    local params = {}
    params.ShowText = ShowText
    params.One_Event = One_Event
    ShowDialogBox( params )
    Set_ShareData( "Previous_Dialog_Content", Localization:getInstance():getText( One_Event.dialogContent, {player = DataManager.getCurrUser().nickName} ) )
    local personName
    if tonumber(One_Event.figureId) == 0 then
        personName = One_Event.ActorName
    else
        local OneData = MetaManager.card_meta[tonumber(One_Event.figureId)]
        if OneData == nil then
            personName = "";
        else
            personName = Localization_getText( OneData.name )
        end
    end
    Set_ShareData( "Previous_Dialog_Person",  personName)
    Set_ShareData("Person_Id_Talker_" .. One_Event.talker, One_Event.figureId)
    Set_ShareData("Previsou_Talker_Exit_Type", One_Event.exitAnimation)
    Set_ShareData("Previsou_Talker_Side", One_Event.talker)
    --print( "End: " .. One_Event.dialogContent )
  end
end
All_DialogBoxes_Hide()

setIsShowDialogSkipButton(0);

enableUserInteraction();

Set_ShareData( "Dialog_Running", 0);
-- Dialog_SetScreenTouchEnabled( true );

print( "All_Dialog_Finished" )

end
