module Tenanted
  class PostsController < BaseController
    before_action :set_post, only: %i[show edit update destroy]

    def index
      @posts = Post.all
    end

    def show
    end

    def new
      @post = Post.new
    end

    def edit
    end

    # POST /posts or /posts.json
    def create
      @post = Post.new(post_params)

      if @post.save
        redirect_to post_url(@post), notice: 'Post was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /posts/1 or /posts/1.json
    def update
      if @post.update(post_params)
        redirect_to post_url(@post), notice: 'Post was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /posts/1 or /posts/1.json
    def destroy
      @post.destroy!
      redirect_to posts_url, notice: 'Post was successfully destroyed.'
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def post_params
      params.require(:post).permit(:title, :content)
    end
  end
end
