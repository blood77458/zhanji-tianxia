



function Run_Script_In_File( FileName_Lua )  --运行文件中的脚本
  if Get_ShareData( "New_User_Guide_Running" ) == 1 then
    return
  end
  RunScript_MultiThread(FileName_Lua, 0);
  
end

Global_CurrentDialogFile = "event_conversation"
function Run_Script_Using_Dialog_Index( Index, activeOpportunity, dialogFile)  --运行剧情对话，参数为第几段对话
  Global_CurrentDialogFile = dialogFile or "event_conversation"
  
  Set_ShareData( "Dialog_Running", 1);
  Set_ShareData( "Show_Dialog_Index", tonumber(Index) );
  if activeOpportunity == nil then activeOpportunity = -999999 end
  Set_ShareData( "Show_Dialog_activeOpportunity", tonumber(activeOpportunity) );
  RunScript_MultiThread( "canon/script_and_guide/Script_All.lua", 0);
  
end









