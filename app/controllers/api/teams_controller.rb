class Api::TeamsController < ApiController
  skip_before_filter :verify_authenticity_token
  skip_before_filter :authenticate_user!
  before_filter :fix_params_from_for, only: :create

  expose(:teams)
  expose(:team)

  def index
    render json: teams
  end

  def show
  end

  def create
    match = MatchRound.round_of_16.available_matches.sample
    team = Team.new(team_params)
    if (team.valid_team? && Team.count < 16)
      team.save
      match.teams << team
      match.start if match.teams.count == 2
      redirect_to root_path
    else
      if Team.count == 16
        flash[:top_teams] = "There are 16 teams already, you cannot create another one"
      elsif team.name == ""
        flash[:team] = "You didn't specify a name for your Team" 
      else
        flash[:player1_errors] = "Player 1 was has not a valid account or email" if team.players[0].is_valid? == false || team.players[0].name.nil?
        flash[:player2_errors] = "Player 2 was has not a valid account or email" if team.players[1].is_valid? == false || team.players[1].name.nil?
      end
      redirect_to :back
    end
  end

  def destroy
    if team.delete
      render json: { message: "The Team was successfully deleted"}
    end
  end

  private
  def team_params
    params.require(:team).permit(
      :name, 
      :picture, 
      players_attributes: [
        :type_account, 
        :user_account, 
        :email, 
        :picture_url
      ]
    )
  end

  def fix_params_from_for
    if params[:team][:players_attributes].first.class == Array
      players_attributes = params["team"]["players_attributes"].to_a
      p1_attributes      = players_attributes.first.last
      p2_attributes      = players_attributes.last.last
      params["team"][:players_attributes] = [p1_attributes, p2_attributes]
    end
  end

end
