return function()

require "canon.script_and_guide.NewUserGuide"

Set_ShareData( "New_User_Guide_Running", 1);
Run_New_User_Guide( 0, 0, 720, 1280, getTextByKey("guide_equipQuality_txt1"), false ,100,200); -- 下面显示的是装备升阶需要的材料，在拥有足够材料时图标就会点亮
Run_New_User_Guide( 0, 0, 720, 1280, getTextByKey("guide_equipQuality_txt2"), false ,100,400); -- 升阶后装备属性会大幅提升！

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
