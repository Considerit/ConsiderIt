module FailedWithException
  def handle_failed_job(job, error)
    super
    ExceptionNotifier.notify_exception(error,
      :data => {:message => "Delayed Job #{job.id} failed, attempt #{job.attempts}"})
  end

end

Delayed::Worker.prepend FailedWithException
