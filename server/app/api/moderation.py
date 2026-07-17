from fastapi import APIRouter, Request
from pydantic import BaseModel

router = APIRouter(tags=["moderation"])

class ReportAction(BaseModel):
    session_token: str
    report_id: int
    action: str  # 'ban', 'warn', 'dismiss'

class ResolveRequest(BaseModel):
    session_token: str
    report_id: int
    action: str = "dismiss"

@router.get("/admin/reports")
async def get_reports(session_token: str, status: str = None, limit: int = 100, request: Request = None):
    from app.services.auth import AuthService
    auth = AuthService(request.app.state.data_layer.db_path)
    user = auth.validate_session(session_token)
    if user.role not in ('admin', 'moderator'):
        return {"status": "error", "message": "Access denied"}
    
    mod = request.app.state.auto_moderator
    reports = mod.get_reports(status=status, limit=limit)
    pending = len(mod.get_reports(status='pending', limit=1000))
    return {"status": "ok", "reports": reports, "pending_count": pending, "total": len(reports)}

@router.post("/admin/reports/resolve")
async def resolve_report(payload: ResolveRequest, request: Request):
    from app.services.auth import AuthService
    auth = AuthService(request.app.state.data_layer.db_path)
    user = auth.validate_session(payload.session_token)
    if user.role not in ('admin', 'moderator'):
        return {"status": "error", "message": "Access denied"}
    
    mod = request.app.state.auto_moderator
    mod.resolve(payload.report_id, payload.action, user.login)
    return {"status": "ok"}
