--------------------------------------------------------------------------------
-- StringUtil.lua - 字符串处理工具集
-- author: xiaojie.bai
-- date: 2013-10-05 15:03
--------------------------------------------------------------------------------

StringUtil = class()

--------------------
-- 去除字符串两端空字符
--------------------
function StringUtil.trim(str)
  if not str then
    return ""
  end
  local len = string.len(str)
  local startIdx = 1
  local endIdx = len
  for i = 1, len do
    local ch = string.sub(str, i, i)
    if(ch == ' ') then
      startIdx = i + 1
    else
      break
    end
  end

  for i = len, 1, -1 do
    local ch = string.sub(str, i, i)
    if(ch == ' ') then
      endIdx = i - 1
    else
      break
    end
  end

  return string.sub(str, startIdx, endIdx)
end

--------------------
-- 字符串切割为数组
--------------------
function StringUtil.split(szFullString, szSeparator)  
  local nFindStartIndex = 1  
  local nSplitIndex = 1  
  local nSplitArray = {}  
  while true do  
    local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)  
    if not nFindLastIndex then  
      nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))  
      break  
    end  
    nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)  
    nFindStartIndex = nFindLastIndex + string.len(szSeparator)  
    nSplitIndex = nSplitIndex + 1  
  end
  
  return nSplitArray  
end  

-----------------------------------------
-- 不影响汉字的utf8字符截断
-----------------------------------------
function StringUtil.truncateUtf8String(s, n)
  local r = string.sub(s, 1, n)
  local last = string.byte(r, n)
  if not last then return r end
  while last >= 128 and last <= 192 do
    n = n - 1
    r = string.sub(r, 1, n)
    last = string.byte(r, n)
  end  
  if last >= 128 then
    r = string.sub(r, 1, n-1)
  end  
  return r 
end

-----------------------------------------
-- 运行返回汉字或字母个数
-----------------------------------------
function StringUtil.calcUtf8StringLength(str)
  local len = #str;
  local left = len;
  local cnt = 0;
  local arr={0,0xc0,0xe0,0xf0,0xf8,0xfc};
  while left ~= 0 do
    local tmp=string.byte(str,-left);
    local i=#arr;
    while arr[i] do
      if tmp>=arr[i] then 
        left=left-i;
        break;
      end
      i=i-1;
    end
    cnt=cnt+1;
  end
  return cnt;
end

-----------------------------------------
-- 运行返回“汉字”与“非汉字”的个数（2个数）
-----------------------------------------
function StringUtil.calcChineseEnglishNum(str)
  local len = #str;
  local left = len;
  local Cnt_Eng = 0;
  local Cnt_Chi = 0;
  local arr={0,0xc0,0xe0,0xf0,0xf8,0xfc};
  while left ~= 0 do
    local tmp=string.byte(str,-left);
    local i=#arr;
    Cnt_Thres = 0;
    while arr[i] do
      if tmp>=arr[i] then 
        left=left-i;
        break;
      end
      i=i-1;
    end
    if i > 1 then
      Cnt_Chi = Cnt_Chi + 1
    else
      Cnt_Eng = Cnt_Eng + 1
    end
  end
  return Cnt_Chi, Cnt_Eng;
end

-----------------------------------------
-- 切割中英文混合字符串成单个中文或英文的table
-----------------------------------------
function StringUtil.splitChineseEnglish(str)
  local result = {}
  local len = #str;
  local left = len;
  local Cnt_Eng = 0;
  local Cnt_Chi = 0;
  local arr={0,0xc0,0xe0,0xf0,0xf8,0xfc};
  local star_index = 1
  while left ~= 0 do
    local tmp=string.byte(str,-left);
    local i=#arr;
    while arr[i] do
      if tmp>=arr[i] then 
        left=left-i;
        break;
      end
      i=i-1;
    end
    local aChar = string.sub(str, star_index, star_index + i - 1)
    table.insert(result, aChar)
    star_index = star_index + i
  end
  return result
end

-----------------------------------------
-- 运行返回“数字”的个数
-----------------------------------------
function StringUtil.calcNumberNum(str)
  local len = #str;
  local left = len;
  local Cnt_Num = 0;
  local Cnt_Chi = 0;
  local arr={0,0xc0,0xe0,0xf0,0xf8,0xfc};
  while left ~= 0 do
    local tmp=string.byte(str,-left);
    print("tmp = " .. tostringRich(tmp))
    if tmp >= 48 and tmp <= 57 then
      Cnt_Num = Cnt_Num + 1
    end
    left=left-1;
  end
  return Cnt_Num;
end