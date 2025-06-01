// my_usb_printer_plugin.cpp
#include <windows.h>
#include <SetupAPI.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <vector>
#include <map>
#include <string>
#include <algorithm>

// Gunakan GUID_DEVINTERFACE_USB_DEVICE untuk enumerasi USB.
DEFINE_GUID(GUID_DEVINTERFACE_USB_DEVICE,
0xA5DCBF10L, 0x6530, 0x11D2, 0x90, 0x1F, 0x00, 0xC0, 0x4F, 0xB9, 0x51, 0xED);

std::vector<std::map<std::string, std::string>> ScanUsbPrinters() {
    std::vector<std::map<std::string, std::string>> printers;
    HDEVINFO deviceInfoSet = SetupDiGetClassDevs(&GUID_DEVINTERFACE_USB_DEVICE, NULL, NULL, DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
    if (deviceInfoSet == INVALID_HANDLE_VALUE) {
        return printers;
    }

    SP_DEVICE_INTERFACE_DATA deviceInterfaceData;
    deviceInterfaceData.cbSize = sizeof(SP_DEVICE_INTERFACE_DATA);
    DWORD index = 0;
    while (SetupDiEnumDeviceInterfaces(deviceInfoSet, NULL, &GUID_DEVINTERFACE_USB_DEVICE, index, &deviceInterfaceData)) {
        DWORD requiredSize = 0;
        SetupDiGetDeviceInterfaceDetail(deviceInfoSet, &deviceInterfaceData, NULL, 0, &requiredSize, NULL);
        if (requiredSize == 0) {
            index++;
            continue;
        }
        std::vector<char> detailDataBuffer(requiredSize);
        PSP_DEVICE_INTERFACE_DETAIL_DATA deviceDetailData = reinterpret_cast<PSP_DEVICE_INTERFACE_DETAIL_DATA>(detailDataBuffer.data());
        deviceDetailData->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA);
        if (SetupDiGetDeviceInterfaceDetail(deviceInfoSet, &deviceInterfaceData, deviceDetailData, requiredSize, NULL, NULL)) {
            std::string devicePath(deviceDetailData->DevicePath);
            std::string lowerPath = devicePath;
            std::transform(lowerPath.begin(), lowerPath.end(), lowerPath.begin(), ::tolower);
            if (lowerPath.find("vid_4b43") != std::string::npos) {
                std::map<std::string, std::string> printer;
                printer["id"] = devicePath;
                printer["name"] = "Caysn Thermal Printer";
                printers.push_back(printer);
            }
        }
        index++;
    }
    SetupDiDestroyDeviceInfoList(deviceInfoSet);
    return printers;
}

void ScanUSBPrintersWindowsMethodCallHandler(
        const flutter::MethodCall<flutter::EncodableValue>& call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    if (call.method_name() == "scanUSBPrintersWindows") {
        auto printers = ScanUsbPrinters();
        flutter::EncodableList printerList;
        for (const auto& printer : printers) {
            flutter::EncodableMap printerMap;
            printerMap[flutter::EncodableValue("id")] = flutter::EncodableValue(printer.at("id"));
            printerMap[flutter::EncodableValue("name")] = flutter::EncodableValue(printer.at("name"));
            printerList.push_back(flutter::EncodableValue(printerMap));
        }
        result->Success(flutter::EncodableValue(printerList));
    } else {
        result->NotImplemented();
    }
}

void RegisterMyUsbPrinterPlugin(flutter::PluginRegistrarWindows* registrar) {
    auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "usb_printer_channel",
                    &flutter::StandardMethodCodec::GetInstance());
    channel->SetMethodCallHandler(
            [](const flutter::MethodCall<flutter::EncodableValue>& call,
               std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
                ScanUSBPrintersWindowsMethodCallHandler(call, std::move(result));
            });
}
