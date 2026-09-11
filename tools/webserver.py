from os.path import split, exists

from fastapi import FastAPI, HTTPException, Body
from fastapi.responses import FileResponse

app = FastAPI()


@app.get("/bundle")
async def download_file():
    file_path = r"D:\Scripting\AresOSV2\bundle.lua"

    if not exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")

    return FileResponse(
        path=file_path,
        filename=split(file_path)[1],
        media_type="application/octet-stream"
    )


@app.get("/test")
async def download_file_test():
    file_path = r"D:\Scripting\AresOSV2\test.lua"

    if not exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")

    return FileResponse(
        path=file_path,
        filename=split(file_path)[1],
        media_type="application/octet-stream"
    )


@app.get("/conf")
async def download_file_conf():
    file_path = r"D:\Scripting\AresOSV2\example_conf.lua"

    if not exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")

    return FileResponse(
        path=file_path,
        filename=split(file_path)[1],
        media_type="application/octet-stream"
    )


@app.get("/plugins/{pluginname}")
async def download_plugin(pluginname: str):
    file_path = rf"D:\Scripting\AresOSV2\plugins\{pluginname}"

    if not file_path.startswith(r"D:\Scripting\AresOSV2\plugins"):
        raise HTTPException(status_code=400, detail="Invalid plugin name")

    if not exists(file_path):
        raise HTTPException(status_code=404, detail="Plugin not found")

    return FileResponse(
        path=file_path,
        filename=split(file_path)[1],
        media_type="application/octet-stream"
    )


@app.post("/recorder")
async def recorder(data: str = Body(..., embed=False)):
    log_path = r"D:\Scripting\AresOSV2\recorder.jsonl"

    with open(log_path, "a", encoding="cp1252") as f:
        f.write(data)
        f.write("\n")

    return {"status": "recorded", "path": log_path}
