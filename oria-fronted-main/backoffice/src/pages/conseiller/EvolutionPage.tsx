import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Search, TrendingUp, BarChart3, Brain } from 'lucide-react'
import * as evolutionService from '@/api/evolution'
import * as eleveService from '@/api/eleves'
import PageHeader from '@/components/shared/PageHeader'
import StatCard from '@/components/ui/StatCard'
import { SkeletonCard } from '@/components/ui/Skeleton'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'

export default function EvolutionPage() {
  const [search, setSearch] = useState('')
  const [selectedStudent, setSelectedStudent] = useState<string | null>(null)

  const { data: students, isLoading: loadingStudents } = useQuery({
    queryKey: ['eleves', 0, search],
    queryFn: () => eleveService.getAll(0, 20),
  })

  const { data: result, isLoading: loadingResult } = useQuery({
    queryKey: ['evolution', selectedStudent],
    queryFn: () => evolutionService.orchestrate(selectedStudent!),
    enabled: !!selectedStudent,
  })

  const engineData = result?.details?.engines?.map((e) => ({
    name: engineLabel(e.name),
    score: Math.round(e.score * 100),
  })) ?? []

  return (
    <div className="space-y-6">
      <PageHeader
        title="Recommandation ORIA"
        description="Analyse multi-dimensions du profil élève"
      />

      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-text-secondary" />
        <input
          type="text"
          placeholder="Rechercher un élève par nom ou email..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full pl-10 pr-4 py-2.5 border border-border rounded-lg bg-white text-text-main text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
        />
      </div>

      {loadingStudents ? (
        <div className="grid grid-cols-1 gap-2">
          {Array.from({ length: 5 }).map((_, i) => (
            <SkeletonCard key={i} />
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
          {(students?.content ?? []).map((s) => (
            <button
              key={s.trackingId}
              onClick={() => setSelectedStudent(s.trackingId)}
              className={`text-left p-4 rounded-xl border transition-colors ${
                selectedStudent === s.trackingId
                  ? 'border-primary bg-primary/5'
                  : 'border-border hover:bg-gray-50'
              }`}
            >
              <p className="font-medium text-text-main">
                {s.prenom} {s.nom}
              </p>
              <p className="text-xs text-text-secondary mt-1">{s.email}</p>
              {s.niveauEtude && (
                <p className="text-xs text-text-secondary mt-0.5">{s.niveauEtude}</p>
              )}
            </button>
          ))}
        </div>
      )}

      {loadingResult && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <SkeletonCard key={i} />
          ))}
        </div>
      )}

      {result && (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <StatCard
              title="Score global"
              value={`${Math.round(result.overallScore * 100)}%`}
              icon={TrendingUp}
              color={result.overallScore >= 0.7 ? 'success' : result.overallScore >= 0.4 ? 'secondary' : 'danger'}
              trend={undefined}
            />
            <StatCard
              title="Moteurs évalués"
              value={result.details?.engines?.length ?? 0}
              icon={Brain}
              color="primary"
              trend={undefined}
            />
            <StatCard
              title="Point fort"
              value={bestEngine(result)}
              icon={BarChart3}
              color="blue"
              trend={undefined}
            />
            <StatCard
              title="Point faible"
              value={worstEngine(result)}
              icon={BarChart3}
              color="danger"
              trend={undefined}
            />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="bg-card rounded-[12px] border border-border p-5">
              <h2 className="text-base font-semibold text-text-main mb-4">
                Scores par moteur
              </h2>
              {engineData.length === 0 ? (
                <p className="text-text-secondary text-sm py-8 text-center">
                  Aucune donnée
                </p>
              ) : (
                <div className="h-72">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={engineData} layout="vertical" barCategoryGap="20%">
                      <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
                      <XAxis type="number" domain={[0, 100]} tick={{ fontSize: 12, fill: '#6B7280' }} />
                      <YAxis
                        dataKey="name"
                        type="category"
                        width={120}
                        tick={{ fontSize: 12, fill: '#6B7280' }}
                      />
                      <Tooltip
                        formatter={(value) => `${Number(value ?? 0)}%`}
                        contentStyle={{ borderRadius: 8, border: '1px solid #E5E7EB', fontSize: 13 }}
                      />
                      <Bar dataKey="score" fill="#3730E8" radius={[0, 4, 4, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              )}
            </div>

            <div className="bg-card rounded-[12px] border border-border p-5">
              <h2 className="text-base font-semibold text-text-main mb-4">
                Résumé
              </h2>
              {result.explainability?.details?.summary ? (
                <div className="text-sm text-text-main whitespace-pre-line leading-relaxed">
                  {(result.explainability.details.summary as string)
                    .split('\n')
                    .map((line, i) => (
                      <p key={i} className={i === 0 ? 'font-semibold mb-2' : 'mb-1'}>
                        {line}
                      </p>
                    ))}
                </div>
              ) : (
                <p className="text-text-secondary text-sm">
                  {result.explainability?.explanation ?? 'Analyse non disponible.'}
                </p>
              )}

              <div className="mt-6 space-y-2">
                {result.details?.engines?.map((engine) => (
                  <div
                    key={engine.name}
                    className="flex items-center justify-between p-3 rounded-lg bg-gray-50"
                  >
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium text-text-main">
                        {engineLabel(engine.name)}
                      </p>
                      <p className="text-xs text-text-secondary truncate">
                        {engine.explanation}
                      </p>
                    </div>
                    <div className="text-right ml-3 shrink-0">
                      <span
                        className={`text-sm font-bold ${
                          engine.score >= 0.7
                            ? 'text-green-600'
                            : engine.score >= 0.4
                              ? 'text-orange-500'
                              : 'text-red-500'
                        }`}
                      >
                        {Math.round(engine.score * 100)}%
                      </span>
                      <p className="text-xs text-text-secondary">
                        poids {Math.round(engine.weight * 100)}%
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </>
      )}

      {!selectedStudent && !loadingStudents && (
        <div className="text-center py-16">
          <Brain className="size-12 mx-auto text-text-secondary/50 mb-4" />
          <p className="text-text-secondary text-sm">
            Sélectionnez un élève pour voir sa recommandation ORIA
          </p>
        </div>
      )}
    </div>
  )
}

function engineLabel(name: string): string {
  const labels: Record<string, string> = {
    academic: 'Académique',
    interest: 'Centres d\'intérêt',
    riasec: 'RIASEC',
    skills: 'Compétences',
    behaviour: 'Comportement',
    activities: 'Activités',
    career: 'Matching métier',
    university: 'Matching université',
    confidence: 'Fiabilité',
    test_engine: 'Test',
  }
  return labels[name] ?? name
}

function bestEngine(result: evolutionService.OrchestratedResult): string {
  const engines = result.details?.engines
  if (!engines || engines.length === 0) return '-'
  const best = engines.reduce((a, b) => (a.score > b.score ? a : b))
  return `${engineLabel(best.name)} (${Math.round(best.score * 100)}%)`
}

function worstEngine(result: evolutionService.OrchestratedResult): string {
  const engines = result.details?.engines
  if (!engines || engines.length === 0) return '-'
  const worst = engines.reduce((a, b) => (a.score < b.score ? a : b))
  return `${engineLabel(worst.name)} (${Math.round(worst.score * 100)}%)`
}
