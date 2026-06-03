#include "flutter_window.h"

#include <flutter_windows.h>
#include <windows.h>

#include <cmath>
#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {

constexpr const wchar_t kWindowPlacementRegKey[] = L"Software\\Flow\\Window";

void SaveDword(HKEY key, const wchar_t* name, int value) {
  DWORD data = static_cast<DWORD>(value);
  RegSetValueEx(key, name, 0, REG_DWORD, reinterpret_cast<const BYTE*>(&data),
                sizeof(data));
}

double ScaleFactorForRect(const RECT& rect) {
  HMONITOR monitor = MonitorFromRect(&rect, MONITOR_DEFAULTTONEAREST);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  return dpi / 96.0;
}

int ToLogicalPixels(LONG value, double scale_factor) {
  return static_cast<int>(std::lround(value / scale_factor));
}

void SaveWindowPlacement(HWND hwnd) {
  WINDOWPLACEMENT placement{};
  placement.length = sizeof(WINDOWPLACEMENT);
  if (!GetWindowPlacement(hwnd, &placement)) {
    return;
  }

  if (placement.showCmd == SW_SHOWMINIMIZED) {
    return;
  }

  RECT bounds = placement.rcNormalPosition;
  const int physical_width = bounds.right - bounds.left;
  const int physical_height = bounds.bottom - bounds.top;
  if (physical_width < 640 || physical_height < 480) {
    return;
  }

  HKEY key = nullptr;
  if (RegCreateKeyEx(HKEY_CURRENT_USER, kWindowPlacementRegKey, 0, nullptr, 0,
                     KEY_SET_VALUE, nullptr, &key, nullptr) != ERROR_SUCCESS) {
    return;
  }

  const double scale_factor = ScaleFactorForRect(bounds);
  SaveDword(key, L"Left", ToLogicalPixels(bounds.left, scale_factor));
  SaveDword(key, L"Top", ToLogicalPixels(bounds.top, scale_factor));
  SaveDword(key, L"Width", ToLogicalPixels(physical_width, scale_factor));
  SaveDword(key, L"Height", ToLogicalPixels(physical_height, scale_factor));
  SaveDword(key, L"Maximized", placement.showCmd == SW_SHOWMAXIMIZED ? 1 : 0);
  RegCloseKey(key);
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_CLOSE:
    case WM_EXITSIZEMOVE:
      SaveWindowPlacement(hwnd);
      break;

    case WM_SIZE:
      if (wparam == SIZE_MAXIMIZED || wparam == SIZE_RESTORED) {
        SaveWindowPlacement(hwnd);
      }
      break;

    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
