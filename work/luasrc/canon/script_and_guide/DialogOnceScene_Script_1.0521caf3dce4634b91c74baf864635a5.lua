return function()

require "canon.script_and_guide.Include_Get_Person_Pic"
local event_conversation = require "canon.configs.event_conversation"
local card_meta = require "canon.configs.card_meta"

print( "DialogOnceScene_Script start running" )
Set_ShareData( "DialogOnceScene_Script_Running", 1 );

Replace_Clicking_With_Timer( 1500, false );
disableUserInteraction();

--setIsShowDialogSkipButton(1);

Set_ShareData( "Last_PicId", 0 ); --初始化(不变)

local DialogIndex = 11111
local activeOpportunity = 2;
--Replace_Clicking_With_Timer( 3000, true );
Clicking_Only();

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
    print( "Begin: " .. One_Event.dialogContent )
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
    print( "End: " .. One_Event.dialogContent )
  end
end
All_DialogBoxes_Hide()

enableUserInteraction();


Set_ShareData( "DialogOnceScene_Script_Running", 0 );
print( "DialogOnceScene_Script all finished" )

end
