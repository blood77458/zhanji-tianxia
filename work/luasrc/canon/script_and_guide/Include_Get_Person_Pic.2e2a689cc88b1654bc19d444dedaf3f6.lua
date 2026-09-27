require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

CommLayer = {}

CommLayer.ShowAction = 1  --仅显示窗口（暂时不用，要改）
CommLayer.WholeAction = 2  --完整过程，显示窗口并等待用户点击，然后完全清除（暂时不用，要改）
CommLayer.NoAnimationAction = 3  --无动画的完整过程，显示窗口并等待用户点击，然后完全清除（可用）

CommLayer.Text_Coversation = 1  --对话
CommLayer.Text_Aside = 2  --旁白
CommLayer.Text_Black_Background = 3  --背景是黑色的旁白
CommLayer.Text_Conversation_Bottom = 4  --显示在最底下的对话

CommLayer.OurSide = 1  --我方 (人物显示在左边)
CommLayer.EnemySide = 2  --对方 (人物显示在右边)
CommLayer.MidSide = -1  --中间


function Guide_Get_Card_FigureId( metaId )
  local This_Card_Meta = require "canon.configs.card_meta"
	local meta = This_Card_Meta[metaId]
	if meta then
    print( "meta.figureId: " .. meta.figureId )
		return tostring(meta.figureId)
	else
    return Guide_Get_Card_FigureId( 101022 )
  end
end








