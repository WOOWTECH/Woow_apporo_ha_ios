#!/bin/bash

ENTITLEMENTS_FILE="${TARGET_TEMP_DIR}/${FULL_PRODUCT_NAME}.xcent"

# 旗標正規化:xcconfig 的 $(ENABLE_X_$(DEVELOPMENT_TEAM)) 在 team 沒有對應定義時會展開成
# 空字串;非 iphoneos SDK 也不會有值。空/未設/非數字一律當 0（停用),
# 避免 [[ "" -eq 1 ]] 之外的形態（例如 "NO"、"1a"）在 build log 噴 bash 算術錯誤。
for _flag in ENABLE_CRITICAL_ALERTS ENABLE_PUSH_PROVIDER ENABLE_THREAD_NETWORK_CREDENTIALS \
             ENABLE_CARPLAY ENABLE_DEVICE_NAME; do
    if [[ ! ${!_flag-} =~ ^[0-9]+$ ]]; then
        printf -v "$_flag" '%s' 0
    fi
done
unset _flag

# PlistBuddy 失敗（key 已存在、.xcent 不存在…）必須看得見,而不是被後面的指令蓋掉退出碼。
add_entitlement() { # add_entitlement <PlistBuddy add 運算式>
    if ! /usr/libexec/PlistBuddy -c "$1" "$ENTITLEMENTS_FILE"; then
        echo "error: PlistBuddy 失敗: $1 ($ENTITLEMENTS_FILE)"
        exit 1
    fi
}

if [[ $CI && $CONFIGURATION != "Release" ]]; then
  echo "warning: Critical alerts disabled for CI"
elif [[ ${ENABLE_CRITICAL_ALERTS} -eq 1 ]]; then
    add_entitlement "add com.apple.developer.usernotifications.critical-alerts bool true"
else
    echo "warning: Critical alerts disabled"
fi

if [[ $CI && $CONFIGURATION != "Release" ]]; then
  echo "warning: Push provider disabled for CI"
elif [[ ${ENABLE_PUSH_PROVIDER} -eq 1 ]]; then
    add_entitlement "add com.apple.developer.networking.networkextension array"
    add_entitlement "add com.apple.developer.networking.networkextension:0 string 'app-push-provider'"
else
    echo "warning: Push provider disabled"
fi

if [[ $TARGET_NAME = "App" ]]; then
    if [[ $CI && $CONFIGURATION != "Release" ]]; then
      echo "warning: THREAD_NETWORK_CREDENTIALS disabled for CI"
    elif [[ ${ENABLE_THREAD_NETWORK_CREDENTIALS} -eq 1 ]]; then
        add_entitlement "add com.apple.developer.networking.manage-thread-network-credentials bool true"
    else
        echo "warning: THREAD_NETWORK_CREDENTIALS disabled"
    fi
fi

if [[ $TARGET_NAME = "App" ]]; then
  if [[ $CI && $CONFIGURATION != "Release" ]]; then
    echo "warning: com.apple.developer.carplay-driving-task disabled for CI"
  elif [[ ${ENABLE_CARPLAY} -eq 1 ]]; then
      add_entitlement "add com.apple.developer.carplay-driving-task bool true"
  else
      echo "warning: com.apple.developer.carplay-driving-task entitlement disabled"
  fi
fi

if [[ $TARGET_NAME = "App" ]]; then
  if [[ $CI && $CONFIGURATION != "Release" ]]; then
    echo "warning: com.apple.developer.carplay-voice-based-conversation disabled for CI"
  elif [[ ${ENABLE_CARPLAY} -eq 1 ]]; then
      add_entitlement "add com.apple.developer.carplay-voice-based-conversation bool true"
  else
      echo "warning: com.apple.developer.carplay-voice-based-conversation entitlement disabled"
  fi
fi


if [[ $TARGET_NAME = "App" ]]; then
  if [[ $CI && $CONFIGURATION != "Release" ]]; then
    echo "warning: Device name disabled for CI"
  elif [[ ${ENABLE_DEVICE_NAME} -eq 1 ]]; then
      add_entitlement "add com.apple.developer.device-information.user-assigned-device-name bool true"
  else
      echo "warning: Device name disabled"
  fi
fi

# 明確以 0 結束:退出碼不該取決於最後一個條件分支是否成立。
exit 0
