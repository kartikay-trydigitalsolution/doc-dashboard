defmodule FirmtechApiWeb.UserJSON do
  alias FirmtechApi.Users.User

  @doc """
  Renders a list of staffs.
  """

  def index(%{meta: %Flop.Meta{} = meta, users: users}) do
    %{data: for(user <- users, do: data(user)), meta: meta}
  end

  @doc """
  Renders a single staff.
  """
  def show(%{user: user}) do
    %{data: data(user)}
  end

  defp data(%User{} = user) do
    %{
      id: user.id,
      sub: user.sub,
      username: user.username,
      onboarded: user.onboarded,
      status: user.status,
      date_of_birth: user.date_of_birth,
      shim_score: user.shim_score,
      weight: user.weight,
      weight_unit: user.weight_unit,
      height: user.height,
      height_unit: user.height_unit,
      bmi: user.bmi,
      diabetes: user.diabetes,
      diabetes_comments: user.diabetes_comments,
      hypertension: user.hypertension,
      hypertension_comments: user.hypertension_comments,
      tobacco: user.tobacco,
      tobacco_comments: user.tobacco_comments,
      alcohol: user.alcohol,
      alcohol_comments: user.alcohol_comments,
      prescription_drugs: user.prescription_drugs,
      prescription_drugs_comments: user.prescription_drugs_comments,
      recreational_drugs: user.recreational_drugs,
      recreational_drugs_comments: user.recreational_drugs_comments,
      personal_comments: user.personal_comments,
      best_score: user.best_score,
      best_score_record_id: user.best_score_record_id,
      best_score_record_started_at: user.best_score_record_started_at,
      last_open_app_at: user.last_open_app_at,
      last_upload_at: user.last_upload_at,
      last_upload_record_id: user.last_upload_record_id,
      first_name: user.first_name,
      last_name: user.last_name,
      staff_notes: user.staff_notes,
      uf_climax: user.uf_climax,
      ed_diagnosis: user.ed_diagnosis,
      ed_concern: user.ed_concern,
      latest_performance_data: user.latest_performance_data,
      language_code: user.language_code,
      notifications_enabled: user.notifications_enabled,
      push_token: user.push_token,
      relationship_status: user.relationship_status,
      relationship_orientation: user.relationship_orientation,
      activity_level: user.activity_level,
      goals: user.goals,
      health_conditions: user.health_conditions,
      medications_data: user.medications_data,
      cannabis: user.cannabis,
      sleep: user.sleep,
      stress: user.stress,
      q1: user.q1,
      q2: user.q2,
      q3: user.q3,
      q4: user.q4,
      q5: user.q5,
      q6: user.q6,
      q7: user.q7,
      q8: user.q8,
      erection_hardness: user.erection_hardness,
      erection_hardness_score: user.erection_hardness_score,
      ehs_score: user.ehs_score,
      shim_severity: user.shim_severity,
      user_consent: user.user_consent,
      permanent_residency_country_code: Map.get(user, :permanent_residency_country_code),
      performance_data: user.performance_data
    }
  end
end
