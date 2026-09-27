function isYidongShortPayInserted()
    --根据平台判断是否已接入移动短代功能
    if isYYBAndroid() then
        return true
    else
        return false
    end
end

function isLiantongShortPayInserted()
    --根据平台判断是否已接入联通短代功能
    --if isYYBAndroid() then
    --    return true
    --else
        return false
    --end
end

function isDianxinShortPayInserted()
    --根据平台判断是否已接入电信短代功能
    --if isYYBAndroid() then
    --    return true
    --else
        return false
    --end
end

function isShortPayInserted()
    if isYidongShortPayInserted() or isLiantongShortPayInserted() or isDianxinShortPayInserted() then
        return true
    else
        return false
    end
end

function judgeCurMobileProvider()
    local provider = 0
    --0:unknow
    --1:移动
    --2:联通
    --3:电信
    --目前只有接入短代的平台可进行运营商判断
    if __ANDROID and isShortPayInserted() then
        provider = CanonEnvInjector:judgeCurAndroidMobileProvider()
        he_log_info("++++++++++++isShortPayOpen() yes:provider _ " .. provider)
        if provider == "unknow" or provider == "unDefined" then
            provider = 0
        end
    end
    return provider
end

function isYidongPayOpen()
    --判断是否可以移动支付
    if isYidongShortPayInserted() and judgeCurMobileProvider() == "1" then
        return true
    else
        return false
    end
end

function isLiantongPayOpen()
    --判断是否可以联通支付
    if isLiantongShortPayInserted() and judgeCurMobileProvider() == "2" then
        return true
    else
        return false
    end
end

function isDianxinPayOpen()
    --判断是否可以电信支付
    if isDianxinShortPayInserted() and judgeCurMobileProvider() == "3" then
        return true
    else
        return false
    end
end

function isShortPayOpen() 
    if isYidongPayOpen() or isLiantongPayOpen() or isDianxinPayOpen() then
        return true
    else
        return false
    end
end