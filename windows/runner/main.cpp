#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <cstdint>
#include "flutter_window.h"
#include "utils.h"

namespace {

constexpr const wchar_t kWindowPlacementRegKey[] = L"Software\\Flow\\Window";

struct SavedWindowState {
  Win32Window::Point origin = Win32Window::Point(10, 10);
  Win32Window::Size size = Win32Window::Size(1280, 720);
  bool maximized = false;
};

bool ReadDword(HKEY key, const wchar_t* name, int* value) {
  DWORD data = 0;
  DWORD data_size = sizeof(data);
  LSTATUS result = RegGetValue(key, nullptr, name, RRF_RT_REG_DWORD, nullptr,
                               &data, &data_size);
  if (result != ERROR_SUCCESS) {
    return false;
  }

  *value = static_cast<int>(static_cast<int32_t>(data));
  return true;
}

bool IsVisibleOnAnyMonitor(const SavedWindowState& state) {
  RECT rect = {state.origin.x, state.origin.y, state.origin.x + state.size.width,
               state.origin.y + state.size.height};
  return MonitorFromRect(&rect, MONITOR_DEFAULTTONULL) != nullptr;
}

SavedWindowState LoadWindowState() {
  SavedWindowState state;

  HKEY key = nullptr;
  if (RegOpenKeyEx(HKEY_CURRENT_USER, kWindowPlacementRegKey, 0, KEY_QUERY_VALUE,
                   &key) != ERROR_SUCCESS) {
    return state;
  }

  int left = 0;
  int top = 0;
  int width = 0;
  int height = 0;
  int maximized = 0;
  const bool has_bounds = ReadDword(key, L"Left", &left) &&
                          ReadDword(key, L"Top", &top) &&
                          ReadDword(key, L"Width", &width) &&
                          ReadDword(key, L"Height", &height);
  ReadDword(key, L"Maximized", &maximized);
  RegCloseKey(key);

  if (!has_bounds || width < 640 || height < 480) {
    return state;
  }

  SavedWindowState loaded = {
      Win32Window::Point(left, top),
      Win32Window::Size(width, height),
      maximized != 0,
  };

  return IsVisibleOnAnyMonitor(loaded) ? loaded : state;
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  SavedWindowState window_state = LoadWindowState();
  FlutterWindow window(project);
  window.SetInitialShowCommand(window_state.maximized ? SW_SHOWMAXIMIZED
                                                      : SW_SHOWNORMAL);
  if (!window.Create(L"Flow", window_state.origin, window_state.size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
