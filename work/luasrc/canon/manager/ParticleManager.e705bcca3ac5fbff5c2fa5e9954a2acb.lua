--------------------------------------------------------------------------------
-- ParticleManager.lua -- 粒子管理器
-- author: Jiang Yize
-- date: 2013-10-29
--------------------------------------------------------------------------------

ParticleManager = {}

-- 生成粒子效果
-- particlePath：路径
-- position：位置
-- scale：缩放比例
-- zOrder：z轴位置
-- container：容器
function ParticleManager.geneParticle(particlePath, position, scale, zOrder, container)
  local particle = CCParticleSystemQuad:create(particlePath)
  particle:setPosition(position)
  particle:setScale(scale)
  local ccParticle = CocosObject.new(particle)
	if zOrder then
		container:addChildAt(ccParticle, zOrder)
	else
		container:addChild(ccParticle)
	end
  ccParticle:setTag(-555)
  return ccParticle
end

-- 对生成的粒子效果进行位移
-- particle: 粒子效果
-- moveTime: 移动时间
-- ccpList: 位置列表
function ParticleManager.moveParticle(particle, moveTime, ccpList)
  local particleMoveArray = CCArray:create()
  local particleMoveTime = moveTime

  for _, ccp in ipairs(ccpList) do
    particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp))
  end
  particle:runAction(CCRepeatForever:create(CCSequence:create(particleMoveArray)))
end
