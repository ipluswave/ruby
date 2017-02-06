class JobsController < ApplicationController
  before_action :set_job, only: [:show, :edit, :update, :destroy]

  # GET /jobs
  # GET /jobs.json
  def index
    @jobs = Job.all
    # @jobs = ScriptedClient::Job.all
  end

  # GET /jobs/1
  # GET /jobs/1.json
  def show
    @job = Job.find(params[:id])
    @job = Job.find(params[:id]).html_contents;
  end

  # GET /jobs/new
  def new
    @job = Job.new
  end

  # GET /jobs/1/edit
  def edit
  end

  # POST /jobs
  # POST /jobs.json
  def create
    # @job = Job.new(job_params)
    #
    # respond_to do |format|
    #   if @job.save
    #     format.html { redirect_to @job, notice: 'Job was successfully created.' }
    #     format.json { render :show, status: :created, location: @job }
    #   else
    #     format.html { render :new }
    #     format.json { render json: @job.errors, status: :unprocessable_entity }
    #   end
    # end
    require 'scripted_client'

# First, find a JobTemplate that you'd like to use:

    templates = ScriptedClient::JobTemplate.all
    blog_post = templates.find { |template| template.name == 'Standard Blog Post' }

# Next, assign some values for the Prompts on that JobTemplate.

    key_points = blog_post.prompts.find { |prompt| prompt.label == 'Key Points' }
    key_points.value = ['Orangutans make great pets', 'Normal pets are lame']

# Next, you can find an Industry:

    industries = ScriptedClient::Industry.all
    lifestyle = industries.find { |industry| industry.name == 'Lifestyle & Travel' }

# Now you can create the Job!

    job = ScriptedClient::Job.new(
        topic: 'Top 10 Reasons to Buy an Orangutan',
        job_template: blog_post,
        industries: [lifestyle]
    )
    job.save
  end

  # PATCH/PUT /jobs/1
  # PATCH/PUT /jobs/1.json
  def update
    respond_to do |format|
      if @job.update(job_params)
        format.html { redirect_to @job, notice: 'Job was successfully updated.' }
        format.json { render :show, status: :ok, location: @job }
      else
        format.html { render :edit }
        format.json { render json: @job.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /jobs/1
  # DELETE /jobs/1.json
  def destroy
    @job.destroy
    respond_to do |format|
      format.html { redirect_to jobs_url, notice: 'Job was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_job
      @job = Job.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def job_params
      params[:job]
    end
end
