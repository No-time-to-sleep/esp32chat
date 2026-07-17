from __future__ import annotations

from fastapi import APIRouter, Request

from app.services.module_registry import ModuleRegistryService


router = APIRouter(tags=["discovery"])


def _registry_service(request: Request) -> ModuleRegistryService:
    data_layer = request.app.state.data_layer
    return ModuleRegistryService(db_path=data_layer.database_path)


@router.get("/api/capabilities")
async def capabilities(request: Request) -> dict[str, object]:
    service = _registry_service(request)
    return {
        "status": "ok",
        "capabilities": service.compute_capability_map(),
    }
