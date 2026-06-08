import { createClient } from 'jsr:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

type DeleteFamilyRpcResult = {
  success?: boolean
  family_id?: string | null
  message?: string | null
  error_code?: string | null
}

function statusForRpcErrorCode(errorCode: string | null | undefined) {
  switch (errorCode) {
    case 'not_authenticated':
      return 401
    case 'no_family':
      return 404
    case 'not_owner':
    case 'family_not_owned_by_user':
      return 403
    case 'family_has_multiple_members':
    case 'multiple_families_not_supported':
      return 409
    default:
      return 400
  }
}

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  })
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (request.method !== 'POST') {
    return jsonResponse(405, {
      success: false,
      message: 'Método não suportado.',
      error_code: 'method_not_allowed',
    })
  }

  if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceRoleKey) {
    return jsonResponse(500, {
      success: false,
      message: 'Configuração do servidor incompleta para excluir a conta.',
      error_code: 'server_misconfigured',
    })
  }

  let body: Record<string, unknown> = {}
  try {
    const rawBody = await request.text()
    if (rawBody.trim().length > 0) {
      body = JSON.parse(rawBody) as Record<string, unknown>
    }
  } catch (_) {
    return jsonResponse(400, {
      success: false,
      message: 'Não foi possível ler a solicitação de exclusão.',
      error_code: 'invalid_request',
    })
  }

  if ('user_id' in body || 'family_id' in body) {
    return jsonResponse(400, {
      success: false,
      message: 'A solicitação de exclusão contém parâmetros não permitidos.',
      error_code: 'invalid_request',
    })
  }

  const authorization = request.headers.get('Authorization')
  if (!authorization) {
    return jsonResponse(401, {
      success: false,
      message: 'Faça login para excluir conta e dados da nuvem.',
      error_code: 'not_authenticated',
    })
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
    global: {
      headers: {
        Authorization: authorization,
      },
    },
  })

  const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  })

  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser()

  if (userError || !user) {
    return jsonResponse(401, {
      success: false,
      message: 'Faça login para excluir conta e dados da nuvem.',
      error_code: 'not_authenticated',
    })
  }

  const { data: rpcData, error: rpcError } = await userClient.rpc(
    'delete_current_owned_family_for_account_deletion',
  )

  if (rpcError) {
    return jsonResponse(500, {
      success: false,
      message: 'Não foi possível excluir conta e dados da nuvem agora.',
      error_code: 'rpc_failed',
      details: rpcError.message,
    })
  }

  const rpcResult = (rpcData ?? {}) as DeleteFamilyRpcResult
  if (rpcResult.success != true) {
    return jsonResponse(statusForRpcErrorCode(rpcResult.error_code), {
      success: false,
      family_id: rpcResult.family_id ?? null,
      message:
        rpcResult.message ??
        'Não foi possível excluir conta e dados da nuvem agora.',
      error_code: rpcResult.error_code ?? 'rpc_blocked',
    })
  }

  const { error: deleteUserError } = await adminClient.auth.admin.deleteUser(
    user.id,
  )

  if (deleteUserError) {
    return jsonResponse(500, {
      success: false,
      family_id: rpcResult.family_id ?? null,
      message:
        'A família foi removida, mas a conta não pôde ser excluída agora.',
      error_code: 'auth_delete_failed',
      details: deleteUserError.message,
    })
  }

  return jsonResponse(200, {
    success: true,
    family_id: rpcResult.family_id ?? null,
    message: 'Sua conta e os dados da família foram removidos da nuvem.',
    error_code: null,
  })
})
