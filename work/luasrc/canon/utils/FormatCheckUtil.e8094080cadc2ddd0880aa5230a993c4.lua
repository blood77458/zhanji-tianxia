
function getCheckAccountErrorStr( errorId )
	if errorId == -1 then
		return "server internal error"
	elseif errorId == -2 then
		return "code params empty"
	elseif errorId == -3 then
		return "sk invalid"
	elseif errorId == -4 then
		return "用户名不存在"
	elseif errorId == -5 then
		return getTextByKey("login_wrong_account")
	else
		return "unknown error"
	end
end

function checkUsernameFormat( username )
	if username:len() < 4 or username:len() > 12 then
		return -1
	end
	if username:match("[%a%d_]+") ~= username then
		return -1
	end
	return 1
end

function checkPasswordFormat( password )
	if password:len() < 6 or password:len() > 15 then
		return -1
	end
	if password:match("[%a%d_]+") ~= password then
		return -1
	end
	return 1
end

function checkPasswordAndConfirm( password, passwordConfirm )
	if checkPasswordFormat(password) ~= 1 or checkPasswordFormat(passwordConfirm) ~= 1 then
		return -1
	end
	if password ~= passwordConfirm then
		return -2
	end
	return 1
end

function checkEmailFormat(email)
	if email == "" then
		return 1
	end
	if email:match("[%a%d%.-_]+@[%w_%.]+%.%w+") ~= email then
		return -1
	end
	return 1
end

function showLoginErrorBox(key, callback)
	CanonMessageBox.showText( ShowButtonType.ID_OK, key, nil, {callbackFunc = callback} ,nil)
end

function secureTextInput(textInput)
	textInput:setInputFlag(kEditBoxInputFlagPassword)
	if __IOS then
		textInput:addEventListener(kTextInputEvents.kChanged, function()
			textInput:setText(textInput:getText())
		end)
	end
end