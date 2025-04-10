FROM python:3.11-slim
WORKDIR /taskManager

# Copy the reuirements.txt file into the container
COPY requirements.txt .

# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container
COPY . .

# Set environment variables
ENV DJANGO_SETTINGS_MODULE=taskManager.settings
ENV DEBUG=True

# Expose the port the app runs on
EXPOSE 8000

# Run migration and collect static files
RUN python manage.py migrate

# Run manage.py to start the server
CMD ["python", "manage.py", "runserver", "0.0.0:8000"]
