<?php
session_start();

// Database connection
$conn = new mysqli("localhost", "root", "", "Caregivers");
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Validate input
if (!isset($_POST['username'], $_POST['password'])) {
    $_SESSION['error'] = "Username or password is missing.";
    header("Location: login.html");
    exit();
}

$username = $conn->real_escape_string($_POST['username']);
$password = $_POST['password'];

// Check user credentials
$sql = "SELECT * FROM member WHERE username = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    if (password_verify($password, $user['passwd'])) {
        $_SESSION['memberID'] = $user['memberID'];
        header("Location: home.html"); // Redirect to the next page
        exit();
    } else {
        $_SESSION['error'] = "Invalid password.";
    }
} else {
    $_SESSION['error'] = "User not found.";
}

// Redirect back to login page if authentication fails
header("Location: login.html");
exit();
?>
