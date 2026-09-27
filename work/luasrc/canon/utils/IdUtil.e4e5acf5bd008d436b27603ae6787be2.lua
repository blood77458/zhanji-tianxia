--------------------------------------------------------------------------------
-- IdUtil.lua - 游戏中id处理及判断的工具类
-- author: xiaojie.bai
-- date: 2013-10-24 16:20
--------------------------------------------------------------------------------
IdUtil = class()

function IdUtil.isCard(metaId)
  return tonumber(metaId) >= 100000 and tonumber(metaId) < 200000
end

function IdUtil.isEquip(metaId)
  return tonumber(metaId) >= 200000 and tonumber(metaId) < 300000
end

function IdUtil.isProp(metaId)
  return tonumber(metaId) >= 400000 and tonumber(metaId) < 500000
end

function IdUtil.isSkill(metaId)
  return tonumber(metaId) >= 30000000 and tonumber(metaId) < 40000000
end

function IdUtil.isEquipFragment(metaId)
  return tonumber(metaId) >= 900000 and tonumber(metaId) < 910000
end

function IdUtil.isSpirit(metaId)
  return tonumber(metaId) >= 600000 and tonumber(metaId) < 700000
end

function IdUtil.isCardFragment(metaId)
  return tonumber(metaId) >= 800000 and tonumber(metaId) < 810000
end