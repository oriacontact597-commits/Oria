import api from './client'

export interface EngineResult {
  name: string
  score: number
  weight: number
  explanation: string
}

export interface OrchestratedResult {
  studentId: string
  overallScore: number
  explainability: {
    score: number
    explanation: string
    details: Record<string, unknown>
  }
  details: {
    orchestratedAt: number
    engines: EngineResult[]
    weights: Record<string, number>
    explainability: Record<string, unknown>
  }
}

export interface StudentEvolutionProfile {
  studentId: string
  version: number
  computedAt: string
  payload: Record<string, unknown>
}

export async function orchestrate(
  studentId: string,
  country?: string,
  config?: string,
): Promise<OrchestratedResult> {
  const params: Record<string, string> = {}
  if (country) params.country = country
  if (config) params.config = config
  const response = await api.post<OrchestratedResult>(
    `/evolution/${studentId}/orchestrate`,
    null,
    { params },
  )
  return response.data
}

export async function compute(studentId: string): Promise<StudentEvolutionProfile> {
  const response = await api.post<StudentEvolutionProfile>(
    `/evolution/${studentId}/compute`,
  )
  return response.data
}

export async function getProfile(studentId: string): Promise<StudentEvolutionProfile> {
  const response = await api.get<StudentEvolutionProfile>(`/evolution/${studentId}`)
  return response.data
}

export async function getDefaultConfig(): Promise<Record<string, number>> {
  const response = await api.get<Record<string, number>>('/evolution/configs')
  return response.data
}
