from io import StringIO

from django.core.management import call_command
from django.test import TestCase

from .models import BlogPost, Project


class GenerateSampleDataCommandTests(TestCase):
    """Tests for the generate_sample_data management command."""

    def call_command(self, *args, **kwargs):
        """Helper to call command and capture output."""
        out = StringIO()
        call_command(
            "generate_sample_data",
            *args,
            stdout=out,
            stderr=StringIO(),
            **kwargs,
        )
        return out.getvalue()

    def test_command_creates_default_number_of_objects(self):
        """Test that command creates default number of blog posts and projects."""
        output = self.call_command()

        self.assertEqual(BlogPost.objects.count(), 10)
        self.assertEqual(Project.objects.count(), 5)
        self.assertIn("Created 10 blog posts", output)
        self.assertIn("Created 5 projects", output)

    def test_command_with_custom_counts(self):
        """Test command with custom counts for posts and projects."""
        output = self.call_command("--posts=3", "--projects=2")

        self.assertEqual(BlogPost.objects.count(), 3)
        self.assertEqual(Project.objects.count(), 2)
        self.assertIn("Created 3 blog posts", output)
        self.assertIn("Created 2 projects", output)

    def test_command_with_clear_flag(self):
        """Test that --clear flag removes existing data."""
        # Create initial data
        BlogPost.objects.create(
            title="Test Post", content="Test content", slug="test-post"
        )
        Project.objects.create(
            title="Test Project", description="Test description", slug="test-project"
        )

        self.assertEqual(BlogPost.objects.count(), 1)
        self.assertEqual(Project.objects.count(), 1)

        # Run command with --clear flag
        output = self.call_command("--posts=2", "--projects=1", "--clear")

        self.assertEqual(BlogPost.objects.count(), 2)
        self.assertEqual(Project.objects.count(), 1)
        self.assertIn("Existing data cleared", output)

    def test_blog_posts_have_required_fields(self):
        """Test that generated blog posts have all required fields populated."""
        self.call_command("--posts=1", "--projects=0")

        blog_post = BlogPost.objects.first()
        self.assertIsNotNone(blog_post)
        self.assertTrue(blog_post.title)
        self.assertTrue(blog_post.slug)
        self.assertTrue(blog_post.content)
        self.assertTrue(blog_post.excerpt)
        self.assertIsNotNone(blog_post.published)
        self.assertIsNotNone(blog_post.created_at)

    def test_projects_have_required_fields(self):
        """Test that generated projects have all required fields populated."""
        self.call_command("--posts=0", "--projects=1")

        project = Project.objects.first()
        self.assertIsNotNone(project)
        self.assertTrue(project.title)
        self.assertTrue(project.slug)
        self.assertTrue(project.description)
        self.assertTrue(project.tech_stack)
        self.assertIsNotNone(project.featured)
        self.assertIsNotNone(project.created_at)

    def test_published_posts_have_published_at_date(self):
        """Test that published blog posts have a published_at date set."""
        self.call_command("--posts=20", "--projects=0")

        published_posts = BlogPost.objects.filter(published=True)
        for post in published_posts:
            self.assertIsNotNone(post.published_at)

    def test_slugs_are_unique(self):
        """Test that generated slugs are unique for each model."""
        self.call_command("--posts=5", "--projects=5")

        blog_slugs = list(BlogPost.objects.values_list("slug", flat=True))
        self.assertEqual(len(blog_slugs), len(set(blog_slugs)))

        project_slugs = list(Project.objects.values_list("slug", flat=True))
        self.assertEqual(len(project_slugs), len(set(project_slugs)))
