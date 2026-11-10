#include <windows.h>
#include <d3d12.h>
#include <dxgi1_6.h>
#include <d3dcompiler.h>
#include <wrl/client.h>
using Microsoft::WRL::ComPtr;

#pragma comment(lib, "d3d12.lib")
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "d3dcompiler.lib")


LRESULT CALLBACK WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
    case WM_DESTROY:
    {
        PostQuitMessage(0);
        return 0;
    }
    break;
    }

    return DefWindowProc(hWnd, message, wParam, lParam);
}


int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PWSTR pCmdLine, int nCmdShow) {
    const int width = 800;
    const int height = 800;

    // Register a simple window class
    WNDCLASS wc = {};
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = L"DirectX12Triangle";
    RegisterClass(&wc);

    // Create a window
    HWND hwnd = CreateWindow(wc.lpszClassName, L"DirectX 12 Triangle", WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, width, height, nullptr, nullptr, hInstance, nullptr);
    ShowWindow(hwnd, nCmdShow);

    /**
    * Make the device - CPU's representation of a SINGLE GPU
    * (unless specified w/ the first nullptr param)
    * 
    * Create a pointer to the device and initialize it to null. Choose the miniumum
    * feature capabilities with the 2nd param and use the third param to ask for an object
    * by interface ID (IID). &Device is type void** and i dont totally get why.
    * 
    * HRESULT hr allows you to check if makign the device was successful or not
    */
    ID3D12Device *device = nullptr;
    HRESULT hr = D3D12CreateDevice(nullptr, D3D_FEATURE_LEVEL_11_0, IID_PPV_ARGS(&device));

    /**
    * Once device is created, we can use it as a factory to create other
    * things like the command queue
    * 
    * When we create a command queue, we need to initialize it to zero using {}
    */
    ID3D12CommandQueue* command_queue = nullptr;
    D3D12_COMMAND_QUEUE_DESC queue_desc = {};
    queue_desc.Type = D3D12_COMMAND_LIST_TYPE_DIRECT; // for typical grpahics use direct
    queue_desc.Flags = D3D12_COMMAND_QUEUE_FLAG_NONE; //nothing special
    hr = device->CreateCommandQueue(&queue_desc, IID_PPV_ARGS(&command_queue)); 

    /**
    * Command Allocator - Memory for storing command lists/ No struct exists. Need to wipe memory
    * in the allocator after every frame, hence hr = command_allocator->Reset();
    */
    ID3D12CommandAllocator *command_allocator = nullptr;
    hr = device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_PPV_ARGS(&command_allocator));
    hr = command_allocator->Reset();


    /**
    * Command List - contains everyhting the GPU should do
    * 
    * 0 - single GPU
    * 
    * DIRECT - Allocator, List and Queue need the same type
    * 
    * command_allocator - memory recorded into
    * 
    * nullptr - whats a PSO?
    * 
    * Interface ID and where to write new list
    */
    ID3D12GraphicsCommandList* command_list = nullptr;
    hr = device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, command_allocator, nullptr, IID_PPV_ARGS(&command_list));
    hr = command_list->Close();

    /**
    * Swapchain - front buffer, back buffer 
    * The back buffer image works with the z depth and 
    * depth buffer to determine which pixel to dislay,
    * which isnt relevant here since only one object (triangle)
    * 
    * IDXGI - DirectX Graphics Infra - deals with system and 
    * screen instead of rendering like D3D12
    * 
    * 
    */
    IDXGIFactory4 *factory = nullptr;
    hr = CreateDXGIFactory1(IID_PPV_ARGS(&factory));
    DXGI_SWAP_CHAIN_DESC swap_chain_desc = {}; //zero-out the struct and instantiate what we care about only
    swap_chain_desc.BufferCount = 2;
    swap_chain_desc.BufferDesc.Width = width;
    swap_chain_desc.BufferDesc.Height = height;
    swap_chain_desc.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    swap_chain_desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    swap_chain_desc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
    swap_chain_desc.OutputWindow = hwnd;
    swap_chain_desc.SampleDesc.Count = 1;
    swap_chain_desc.Windowed = TRUE;


    bool running = true;
    while (running) {
        MSG msg = {};
        while (PeekMessage(&msg, nullptr, 0, 0, PM_REMOVE)) {
            if (msg.message == WM_QUIT) {
                running = false;
                break;
            }
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }
}
