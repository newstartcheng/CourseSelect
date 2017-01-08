class CoursesController < ApplicationController

  before_action :student_logged_in, only: [:select, :quit, :list]
  before_action :teacher_logged_in, only: [:new, :create, :edit, :destroy, :update]
  before_action :logged_in, only: :index

  #-------------------------for teachers----------------------

  def new
    @course=Course.new
  end

  def create
    @course = Course.new(course_params)
    if @course.save
      current_user.teaching_courses<<@course
      redirect_to courses_path, flash: {success: "新课程申请成功"}
    else
      flash[:warning] = "信息填写有误,请重试"
      render 'new'
    end
  end

  def edit
    @course=Course.find_by_id(params[:id])
  end

  def update
    @course = Course.find_by_id(params[:id])
    if @course.update_attributes(course_params)
      flash={:info => "更新成功"}
    else
      flash={:warning => "更新失败"}
    end
    redirect_to courses_path, flash: flash
  end

  def destroy
    @course=Course.find_by_id(params[:id])
    current_user.teaching_courses.delete(@course)
    @course.destroy
    flash={:success => "成功删除课程: #{@course.name}"}
    redirect_to courses_path, flash: flash
  end

  #-------------------------for students----------------------

  def list
     #   按照关键词（课程名称、教师名）或者下拉列表进行查询
    @course = Course.all

    @param1 =  params[:queryKeyword_1]   #课程名
    @param2= params[:queryKeyword_2]  #department
    @param3= params[:queryKeyword_3] #credit/hour
    @param4 =params[:queryKeyword_4] #type
    @param5= params[:queryKeyword_5] #exam
    if @param1.nil? ==  false and @param1 != ''
      @course = Course.where("name like '%#{@param1}%'")  
    end  
    if @param2.nil? == false and @param2 != ''
      @course = @course.where("course_code like '#{@param2}%'")
    end
    if @param3.nil? == false and @param3 != ''
      @course = @course.where("credit like '#{@param3}'")
        end
    if @param4.nil? == false and @param4 != ''
      @course = @course.where("course_type like '#{@param4}'")
        end
    if @param5.nil? == false and @param5 != ''
     @course = @course.where("exam_type like '#{@param5}'")
    end

     @course=@course-current_user.courses
     @course_true = Array.new 
     @course.each do |single| 
       if single.open then 
         @course_true.push single 
       end 
     end 
     @course=@course_true 
   
  end
  
  def public_list 
    @course=Course.all
  end
  
  
    
  
  
  def select
    @allcourse=current_user.courses
    @course=Course.find_by_id(params[:id])

    @allcourse.each do |k|
      if(k.course_week.nil?||@course.course_week.nil?)
        next
      else
        week1 = (@course.course_week[0,1].to_i..@course.course_week[3,@course.course_week.length-1].to_i).to_a
        week2 = (k.course_week[0,1].to_i..k.course_week[3,k.course_week.length-1].to_i).to_a
        time1 = (@course.course_time[3].to_i..@course.course_time[5,@course.course_time.length-1].to_i).to_a
        time2 = (k.course_time[3].to_i..k.course_time[5,k.course_time.length-1].to_i).to_a
        weekn1=@course.course_time[2]
        weekn2=k.course_time[2]
      
        if (week1 & week2)!=[] && (time1 & time2)!=[] && weekn1==weekn2
      
          flash={:sucess => "选课时间冲突: #{@course.name}"}
          redirect_to list_courses_path, flash: flash
          return
        end
      end
   end

    if !@course.limit_num.nil? && @course.limit_num!=0
      if(@course.student_num < @course.limit_num)
        current_user.courses<<@course
        @course.student_num+=1
        @course.update_attributes(:student_num=>@course.student_num)
        flash={:success => "成功选择课程: #{@course.name}"}
        redirect_to courses_path, flash: flash
      else
        flash={:danger => "选课人数已满: #{@course.name}"}
        @course_open=Course.where(:open=>true)
        @course_open=@course_open-current_user.courses
        @course=@course_open
        redirect_to list_courses_path, flash: flash
      end
    else
       current_user.courses<<@course
        @course.student_num+=1
        @course.update_attributes(:student_num=>@course.student_num)
        flash={:success => "成功选择课程: #{@course.name}"}
        redirect_to courses_path, flash: flash
    end     
  end

  def quit
    @course=Course.find_by_id(params[:id])
    current_user.courses.delete(@course)
    @course.student_num-=1
    @course.update_attributes(:student_num=>@course.student_num)
    flash={:success => "成功退选课程: #{@course.name}"}
    redirect_to courses_path, flash: flash
  end
  def credittips
     @courses=current_user.courses
     @grades=current_user.grades
  end
  
 def filter
    redirect_to list_courses_path(params)
 end
 
  def open 
    @course = Course.find_by_id(params[:id])
    @course.update_attributes(:open=>true)
    redirect_to courses_path, flash: {:success => "已经成功开放该课程:#{ @course.name}"}
  end 
 
  def close
    @course = Course.find_by_id(params[:id])
    @course.update_attributes(:open=>false) 
    redirect_to courses_path, flash: {:success => "已经成功关闭该课程:#{ @course.name}"} 
  end
  #-------------------------for both teachers and students----------------------

  def index
    @course=current_user.teaching_courses if teacher_logged_in?
    @course=current_user.courses if student_logged_in?
  end


  private

  # Confirms a student logged-in user.
  def student_logged_in
    unless student_logged_in?
      redirect_to root_url, flash: {danger: '请登陆'}
    end
  end

  # Confirms a teacher logged-in user.
  def teacher_logged_in
    unless teacher_logged_in?
      redirect_to root_url, flash: {danger: '请登陆'}
    end
  end

  # Confirms a  logged-in user.
  def logged_in
    unless logged_in?
      redirect_to root_url, flash: {danger: '请登陆'}
    end
  end

  def course_params
    params.require(:course).permit(:course_code, :name, :course_type, :teaching_type, :exam_type,
                                   :credit, :limit_num, :class_room, :course_time, :course_week)
  end


end
